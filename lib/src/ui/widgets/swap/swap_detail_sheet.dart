import 'dart:async';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/swap_monitoring_service.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
  final SwapMonitoringService _swapMonitor = SwapMonitoringService();
  SwapInfo? _swapInfo;
  bool _isLoading = true;
  bool _isRefunding = false;
  bool _isClaiming = false;
  String? _errorMessage;
  Timer? _pollTimer;

  // Copy feedback states
  bool _showSwapIdCopied = false;
  bool _showEvmContractCopied = false;
  bool _showArkadeHtlcCopied = false;
  bool _showTxCopied = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSwapItem != null) {
      _swapInfo = widget.initialSwapItem!.swap;
      _isLoading = false;
    }
    _loadSwapInfo();
    _startPollingIfNeeded();
    // Listen for background claim state changes
    _swapMonitor.addListener(_onMonitorStateChanged);
  }

  void _onMonitorStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _swapMonitor.removeListener(_onMonitorStateChanged);
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

  void _copySwapId() {
    Clipboard.setData(ClipboardData(text: widget.swapId));
    HapticFeedback.lightImpact();
    setState(() => _showSwapIdCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSwapIdCopied = false);
    });
  }

  void _copyEvmContract() {
    if (_swapInfo?.evmHtlcAddress == null) return;
    Clipboard.setData(ClipboardData(text: _swapInfo!.evmHtlcAddress!));
    HapticFeedback.lightImpact();
    setState(() => _showEvmContractCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showEvmContractCopied = false);
    });
  }

  void _copyArkadeHtlc() {
    if (_swapInfo?.arkadeHtlcAddress == null) return;
    Clipboard.setData(ClipboardData(text: _swapInfo!.arkadeHtlcAddress!));
    HapticFeedback.lightImpact();
    setState(() => _showArkadeHtlcCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showArkadeHtlcCopied = false);
    });
  }

  void _copyTxHash() {
    if (_swapInfo?.evmHtlcClaimTxid == null) return;
    Clipboard.setData(ClipboardData(text: _swapInfo!.evmHtlcClaimTxid!));
    HapticFeedback.lightImpact();
    setState(() => _showTxCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTxCopied = false);
    });
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

        // Track swap transaction for analytics
        await AnalyticsService().trackSwapTransaction(
          amountSats: _swapInfo!.sourceAmountSats.toInt(),
          fromAsset: _swapInfo!.sourceToken,
          toAsset: _swapInfo!.targetToken,
          swapId: widget.swapId,
        );

        if (mounted) {
          OverlayService()
              .showSuccess('Claim submitted! Funds will arrive shortly.');
        }
      } else if (_swapInfo!.canClaimVhtlc) {
        logger.i('Claiming EVM→BTC swap via VHTLC');
        final txid = await _swapService.claimVhtlc(widget.swapId);

        // Track swap transaction for analytics
        await AnalyticsService().trackSwapTransaction(
          amountSats: _swapInfo!.sourceAmountSats.toInt(),
          fromAsset: _swapInfo!.sourceToken,
          toAsset: _swapInfo!.targetToken,
          swapId: widget.swapId,
        );

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffoldUnsafe(
      context: context,
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: BitNetAppBar(
        context: context,
        text: 'Swap Details',
        hasBackButton: false,
      ),
      body: _isLoading
          ? dotProgress(context)
          : _errorMessage != null && _swapInfo == null
              ? _buildErrorState(context)
              : _buildContent(context, isDarkMode),
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

  Widget _buildContent(BuildContext context, bool isDarkMode) {
    final sourceToken = _getSourceToken();
    final targetToken = _getTargetToken();
    final status = _swapInfo?.status ?? SwapStatusSimple.waitingForDeposit;

    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        // Close bottom sheet when user overscrolls at the top
        if (notification.overscroll < 0 && notification.metrics.pixels == 0) {
          Navigator.of(context).pop();
          return true;
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.cardPadding * 3,
          ),
          child: Column(
            children: [
              // Status header in its own GlassContainer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: GlassContainer(
                    borderRadius: AppTheme.cardRadiusBig,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.cardPadding,
                        horizontal: AppTheme.elementSpacing,
                      ),
                      child: _buildStatusHeader(context, status, isDarkMode),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              // Main card with swap summary and details
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                ),
                child: GlassContainer(
                  borderRadius: AppTheme.cardRadiusBig,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.elementSpacing,
                      horizontal: AppTheme.elementSpacing,
                    ),
                    child: Column(
                      children: [
                        // Swap summary (amounts) in its own box
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.5,
                            vertical: AppTheme.elementSpacing,
                          ),
                          child: GlassContainer(
                            opacity: 0.05,
                            borderRadius: AppTheme.cardRadiusSmall,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(AppTheme.cardPadding),
                              child: _buildSwapSummaryCompact(context,
                                  sourceToken, targetToken, isDarkMode),
                            ),
                          ),
                        ),
                        // Swap details (nested container)
                        _buildSwapDetails(context, isDarkMode),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.cardPadding),
              // Action buttons outside the main card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.cardPadding,
                ),
                child: _buildActionButtons(context, status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
      BuildContext context, SwapStatusSimple status, bool isDarkMode) {
    final statusInfo = _getStatusInfo(status);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: statusInfo.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(statusInfo.icon, size: 40, color: statusInfo.color),
        ),
        const SizedBox(height: AppTheme.elementSpacing),
        Text(
          statusInfo.text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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

  /// Swap summary with token icons - original design within the unified card
  Widget _buildSwapSummaryCompact(BuildContext context, SwapToken sourceToken,
      SwapToken targetToken, bool isDarkMode) {
    final btcAmount = _swapInfo != null
        ? ((_swapInfo!.sourceAmountSats.toInt()) / BitcoinConstants.satsPerBtc)
            .toStringAsFixed(8)
        : '0';
    final tokenAmount = _swapInfo?.targetAmountUsd.toStringAsFixed(
            sourceToken.isStablecoin || targetToken.isStablecoin ? 2 : 6) ??
        '0.00';

    // Format amount based on token type
    String formatTokenAmount(SwapToken token, String amount) {
      if (token.isBtc) {
        return '$btcAmount BTC';
      } else if (token.isStablecoin) {
        return '\$$amount';
      } else {
        // Non-stablecoin (XAUT, etc.)
        return '$amount ${token.symbol}';
      }
    }

    return Column(
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
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                  Text(
                    formatTokenAmount(sourceToken, tokenAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${sourceToken.symbol} (${sourceToken.network})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 20,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                  Text(
                    formatTokenAmount(targetToken, tokenAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _swapInfo?.status == SwapStatusSimple.completed
                              ? AppTheme.successColor
                              : null,
                        ),
                  ),
                  Text(
                    '${targetToken.symbol} (${targetToken.network})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwapDetails(BuildContext context, bool isDarkMode) {
    if (_swapInfo == null) return const SizedBox.shrink();

    final currencyService = context.watch<CurrencyPreferenceService>();
    final showCoinBalance = currencyService.showCoinBalance;

    final createdAt = _formatTimestamp(_swapInfo!.createdAt);
    final feeSats = _swapInfo!.feeSats.toInt();
    final (feeAmount, feeUnit, isSatsUnit) = _formatFeeWithUnit(feeSats);

    // Calculate fiat value of fee using the swap's exchange rate
    // Exchange rate = targetAmountUsd / (sourceAmountSats / satsPerBtc)
    final sourceAmountSats = _swapInfo!.sourceAmountSats.toInt();
    final targetAmountUsd = _swapInfo!.targetAmountUsd;
    final btcPrice = sourceAmountSats > 0
        ? targetAmountUsd / (sourceAmountSats / BitcoinConstants.satsPerBtc)
        : 0.0;
    final feeFiat = (feeSats / BitcoinConstants.satsPerBtc) * btcPrice;
    final feeFiatFormatted = currencyService.formatAmount(feeFiat);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.elementSpacing * 0.5,
        vertical: AppTheme.elementSpacing,
      ),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: AppTheme.cardRadiusSmall,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.elementSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Swap ID with copy feedback
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing * 0.75,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: 'Swap ID',
                onTap: _copySwapId,
                trailing: SizedBox(
                  width: AppTheme.cardPadding * 6,
                  child: _showSwapIdCopied
                      ? Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.check,
                              color: AppTheme.successColor,
                              size: AppTheme.cardPadding * 0.75,
                            ),
                            const SizedBox(width: AppTheme.elementSpacing / 2),
                            const Text(
                              'Copied',
                              style: TextStyle(color: AppTheme.successColor),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Text(
                                widget.swapId,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTheme.elementSpacing / 2),
                            Icon(
                              Icons.copy,
                              color: AppTheme.white60,
                              size: AppTheme.cardPadding * 0.75,
                            ),
                          ],
                        ),
                ),
              ),

              // Direction
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing * 0.75,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: 'Direction',
                trailing: Text(
                  _swapInfo!.direction == 'btc_to_evm'
                      ? 'BTC → ${_getTargetToken().symbol}'
                      : '${_getSourceToken().symbol} → BTC',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              // Created
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing * 0.75,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: 'Created',
                trailing: Text(
                  createdAt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              // Fee (tappable to toggle sats/fiat)
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing * 0.75,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: 'Fee',
                onTap: () => currencyService.toggleShowCoinBalance(),
                trailing: showCoinBalance
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            feeAmount,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 2),
                          if (isSatsUnit)
                            Icon(
                              AppTheme.satoshiIcon,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          else
                            Text(
                              ' $feeUnit',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                        ],
                      )
                    : Text(
                        feeFiatFormatted,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              ),

              // EVM Contract with copy feedback
              if (_swapInfo!.evmHtlcAddress != null)
                ArkListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.elementSpacing * 0.75,
                    vertical: AppTheme.elementSpacing * 0.5,
                  ),
                  text: 'EVM Contract',
                  onTap: _copyEvmContract,
                  trailing: SizedBox(
                    width: AppTheme.cardPadding * 6,
                    child: _showEvmContractCopied
                        ? Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.check,
                                color: AppTheme.successColor,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              const Text(
                                'Copied',
                                style: TextStyle(color: AppTheme.successColor),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Text(
                                  _swapInfo!.evmHtlcAddress!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              Icon(
                                Icons.copy,
                                color: AppTheme.white60,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                            ],
                          ),
                  ),
                ),

              // Arkade HTLC with copy feedback
              if (_swapInfo!.arkadeHtlcAddress != null)
                ArkListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.elementSpacing * 0.75,
                    vertical: AppTheme.elementSpacing * 0.5,
                  ),
                  text: 'Arkade HTLC',
                  onTap: _copyArkadeHtlc,
                  trailing: SizedBox(
                    width: AppTheme.cardPadding * 6,
                    child: _showArkadeHtlcCopied
                        ? Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.check,
                                color: AppTheme.successColor,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              const Text(
                                'Copied',
                                style: TextStyle(color: AppTheme.successColor),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Text(
                                  _swapInfo!.arkadeHtlcAddress!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              Icon(
                                Icons.copy,
                                color: AppTheme.white60,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                            ],
                          ),
                  ),
                ),

              // Transaction hash with copy feedback
              if (_swapInfo!.evmHtlcClaimTxid != null &&
                  _swapInfo!.direction == 'btc_to_evm')
                ArkListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.elementSpacing * 0.75,
                    vertical: AppTheme.elementSpacing * 0.5,
                  ),
                  text: 'Transaction',
                  onTap: _copyTxHash,
                  trailing: SizedBox(
                    width: AppTheme.cardPadding * 6,
                    child: _showTxCopied
                        ? Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.check,
                                color: AppTheme.successColor,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              const Text(
                                'Copied',
                                style: TextStyle(color: AppTheme.successColor),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Text(
                                  _swapInfo!.evmHtlcClaimTxid!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              Icon(
                                Icons.copy,
                                color: AppTheme.white60,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns (formattedAmount, unit, isSatsUnit)
  (String, String, bool) _formatFeeWithUnit(int feeSats) {
    if (feeSats >= 100000) {
      // Show in BTC for large amounts
      final btc = feeSats / BitcoinConstants.satsPerBtc;
      return (btc.toStringAsFixed(8), 'BTC', false);
    } else if (feeSats >= 1000) {
      // Show in sats with comma formatting
      return (_formatNumber(feeSats), 'sats', true);
    } else {
      return (feeSats.toString(), 'sats', true);
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
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
    // Only show deposit button for EVM → BTC swaps (user needs to send EVM tokens)
    final showDepositButton = isWaitingForDeposit &&
        _swapInfo?.direction == 'evm_to_btc' &&
        _swapInfo?.depositAddress != null;

    if (!canClaim && !canRefund && !showDepositButton) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Deposit button for pending EVM → BTC swaps
        if (showDepositButton) ...[
          LongButtonWidget(
            title: 'Deposit',
            customWidth: double.infinity,
            onTap: _navigateToDeposit,
          ),
          const SizedBox(height: AppTheme.cardPadding),
        ],
        // Claim section
        if (canClaim) ...[
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: Text(
                      _swapInfo!.canClaimGelato
                          ? 'Your swap is ready! Claim your ${_getTargetToken().symbol} now.'
                          : 'Your swap is ready! Claim your BTC now.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.successColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          Builder(builder: (context) {
            // Check both local claiming state and background auto-claim state
            final isClaimingAnywhere =
                _isClaiming || _swapMonitor.isClaimingSwap(widget.swapId);
            return LongButtonWidget(
              title: _swapInfo!.canClaimGelato
                  ? 'Claim ${_getTargetToken().symbol}'
                  : 'Claim BTC',
              customWidth: double.infinity,
              state:
                  isClaimingAnywhere ? ButtonState.loading : ButtonState.idle,
              onTap: isClaimingAnywhere ? null : _handleClaim,
            );
          }),
        ],
        // Refund section
        if (canRefund) ...[
          if (canClaim) const SizedBox(height: AppTheme.cardPadding),
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: Text(
                      'This swap did not complete. You can claim a refund to recover your funds.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          LongButtonWidget(
            title: 'Claim Refund',
            customWidth: double.infinity,
            state: _isRefunding ? ButtonState.loading : ButtonState.idle,
            buttonType: ButtonType.secondary,
            onTap: _isRefunding ? null : _handleRefund,
          ),
        ],
        // Bottom spacing
        const SizedBox(height: AppTheme.cardPadding),
      ],
    );
  }

  String _truncateId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }

  String _formatTimestamp(String timestamp) {
    try {
      // Handle format like "2025-12-21 19:04:15.0 +00:00:00" or "2025-12-24 3:24:25.0 +00:00:00"
      // Remove the extra timezone format and normalize
      String normalizedTimestamp = timestamp;

      // Replace space before timezone with 'T' for ISO format
      // and handle the unusual "+00:00:00" format
      if (timestamp.contains(' +') || timestamp.contains(' -')) {
        // Split at the timezone part
        final parts = timestamp.split(RegExp(r' [+-]'));
        if (parts.isNotEmpty) {
          normalizedTimestamp = parts[0].trim();
        }
      }

      // Pad single-digit hour (e.g., "3:24:25" -> "03:24:25")
      final dateTimeParts = normalizedTimestamp.split(' ');
      if (dateTimeParts.length == 2) {
        final datePart = dateTimeParts[0];
        var timePart = dateTimeParts[1];

        final timeComponents = timePart.split(':');
        if (timeComponents.isNotEmpty && timeComponents[0].length == 1) {
          timeComponents[0] = '0${timeComponents[0]}';
          timePart = timeComponents.join(':');
        }

        normalizedTimestamp = '$datePart $timePart';
      }

      // Replace space between date and time with 'T' for ISO format
      normalizedTimestamp = normalizedTimestamp.replaceFirst(' ', 'T');

      // Add Z suffix to indicate UTC (server sends UTC timestamps)
      if (!normalizedTimestamp.contains('Z') &&
          !normalizedTimestamp.contains('+')) {
        normalizedTimestamp += 'Z';
      }

      final date = DateTime.parse(normalizedTimestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds} seconds ago';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 30) {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    } catch (e) {
      logger.e('Error parsing timestamp: $timestamp - $e');
      return timestamp;
    }
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
    // Ark bech32m addresses
    if (address.startsWith('ark1') || address.startsWith('tark1')) {
      return address.length >= 20;
    }
    // Bitcoin bech32 addresses
    if (address.startsWith('bc1') || address.startsWith('tb1')) {
      return address.length >= 26;
    }
    // Legacy Bitcoin addresses
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
        _errorText = 'Invalid Bitcoin/Arkade address';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            'Enter the Bitcoin or Arkade address where you want to receive your refund.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'ark1... or bc1...',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
