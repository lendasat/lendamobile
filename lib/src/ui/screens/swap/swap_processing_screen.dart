import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/swap_monitoring_service.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/qr_border_painter.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/swap/wallet_connect_button.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_success_screen.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Screen that shows the processing status of an ongoing swap.
class SwapProcessingScreen extends StatefulWidget {
  final String swapId;
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;

  /// Optional loan contract ID for loan repayment swaps
  final String? loanContractId;

  /// Optional loan installment ID for loan repayment swaps
  final String? loanInstallmentId;

  const SwapProcessingScreen({
    super.key,
    required this.swapId,
    required this.sourceToken,
    required this.targetToken,
    required this.sourceAmount,
    required this.targetAmount,
    this.loanContractId,
    this.loanInstallmentId,
  });

  @override
  State<SwapProcessingScreen> createState() => _SwapProcessingScreenState();
}

class _SwapProcessingScreenState extends State<SwapProcessingScreen> {
  final LendaSwapService _swapService = LendaSwapService();
  final SwapMonitoringService _swapMonitor = SwapMonitoringService();
  final WalletConnectService _walletService = WalletConnectService();
  SwapInfo? _swapInfo;
  Timer? _pollTimer;
  StreamSubscription<SwapClaimEvent>? _claimSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showWalletConnectClaim = false;
  bool _isClaimingWalletConnect = false;

  @override
  void initState() {
    super.initState();
    // Tell the monitoring service to watch this swap
    _swapMonitor.startMonitoringSwap(widget.swapId);
    _loadSwapInfo();
    _startPolling();
    _listenToClaimEvents();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _claimSubscription?.cancel();
    super.dispose();
  }

  void _listenToClaimEvents() {
    _claimSubscription = _swapMonitor.claimEvents.listen((event) {
      if (event.swapId == widget.swapId && event.success) {
        logger.i('[SwapProcessing] Received claim success event for our swap');
        // Refresh to get updated status
        _loadSwapInfo();
      }
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadSwapInfo();
    });
  }

  Future<void> _loadSwapInfo() async {
    logger.d('[SwapProcessing] _loadSwapInfo called for swap ${widget.swapId}');
    try {
      final swap = await _swapService.getSwap(widget.swapId);
      logger.i('[SwapProcessing] Got swap info:');
      logger.i('[SwapProcessing] - id: ${swap.id}');
      logger.i('[SwapProcessing] - status: ${swap.status}');
      logger.i('[SwapProcessing] - detailedStatus: ${swap.detailedStatus}');
      logger.i('[SwapProcessing] - canClaimGelato: ${swap.canClaimGelato}');
      logger.i('[SwapProcessing] - canClaimVhtlc: ${swap.canClaimVhtlc}');
      logger.i('[SwapProcessing] - isCompleted: ${swap.isCompleted}');

      if (mounted) {
        setState(() {
          _swapInfo = swap;
          _isLoading = false;
        });

        // Check if completed or failed
        if (swap.isCompleted) {
          logger.i('[SwapProcessing] Swap is COMPLETED! Navigating to success');
          _pollTimer?.cancel();
          _navigateToSuccess();
        } else if (swap.status == SwapStatusSimple.failed ||
            swap.status == SwapStatusSimple.expired) {
          logger.w('[SwapProcessing] Swap is FAILED or EXPIRED.');
          _pollTimer?.cancel();
        } else {
          // For BTC → EVM swaps that don't require WalletConnect,
          // navigate back to wallet - monitoring service handles completion
          if (widget.sourceToken.isBtc &&
              !_swapMonitor.requiresWalletConnect(swap)) {
            final isProcessing = swap.status == SwapStatusSimple.processing ||
                swap.status == SwapStatusSimple.waitingForDeposit;
            if (isProcessing) {
              logger.i(
                  '[SwapProcessing] BTC→EVM swap processing via Gelato - returning to wallet');
              _pollTimer?.cancel();
              _navigateBackToWallet();
              return;
            }
          }
          // Auto-claim via SwapMonitoringService
          await _attemptAutoClaim(swap);
        }
      }
    } catch (e) {
      logger.e('[SwapProcessing] _loadSwapInfo FAILED: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Attempt to auto-claim the swap using SwapMonitoringService.
  Future<void> _attemptAutoClaim(SwapInfo swap) async {
    // For Ethereum targets, show WalletConnect UI (requires gas payment)
    if (_swapMonitor.requiresWalletConnect(swap)) {
      logger.i(
          '[SwapProcessing] Ethereum target - showing WalletConnect claim UI');
      if (!_showWalletConnectClaim) {
        setState(() => _showWalletConnectClaim = true);
      }
      return;
    }

    // Let the monitoring service handle claiming
    if (swap.canClaimGelato || swap.canClaimVhtlc) {
      logger.d('[SwapProcessing] Triggering claim via SwapMonitoringService');
      await _swapMonitor.claimSwapIfReady(swap);
    }
  }

  /// Navigate back to wallet screen - swap will complete in background
  void _navigateBackToWallet() {
    if (!mounted) return;

    OverlayService()
        .showSuccess('Swap processing - you\'ll be notified when complete');

    // Pop back to wallet (through all swap screens)
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Trigger wallet refresh
    PaymentMonitoringService().switchToWalletTab();
  }

  Future<void> _navigateToSuccess() async {
    // If this is a loan repayment swap, automatically mark the installment as paid
    if (widget.loanContractId != null &&
        widget.loanInstallmentId != null &&
        _swapInfo?.evmHtlcClaimTxid != null) {
      logger.i(
          '[SwapProcessing] Loan repayment swap completed! Auto-marking installment as paid');
      logger.i('[SwapProcessing] - Contract ID: ${widget.loanContractId}');
      logger
          .i('[SwapProcessing] - Installment ID: ${widget.loanInstallmentId}');
      logger
          .i('[SwapProcessing] - Payment TXID: ${_swapInfo!.evmHtlcClaimTxid}');

      try {
        final lendasatService = LendasatService();
        await lendasatService.markInstallmentPaid(
          contractId: widget.loanContractId!,
          installmentId: widget.loanInstallmentId!,
          paymentTxid: _swapInfo!.evmHtlcClaimTxid!,
        );
        logger.i('[SwapProcessing] Successfully marked installment as paid!');
        if (mounted) {
          OverlayService().showSuccess('Loan repayment confirmed!');
        }
      } catch (e) {
        logger
            .e('[SwapProcessing] Failed to auto-mark installment as paid: $e');
        // Don't block navigation - user can still manually confirm later
        if (mounted) {
          OverlayService().showError(
              'Swap completed but failed to auto-confirm repayment. Please use "I Already Paid" to confirm manually.');
        }
      }
    }

    if (!mounted) return;

    // Trigger wallet refresh when swap completes
    PaymentMonitoringService().switchToWalletTab();

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
    HapticFeedback.lightImpact();
    if (mounted) {
      OverlayService().showSuccess('Copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: 'Swap in Progress',
        hasBackButton: true,
      ),
      body: _isLoading
          ? dotProgress(context)
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
          // WalletConnect claim UI for Ethereum swaps
          if (_showWalletConnectClaim) ...[
            _buildWalletConnectClaimSection(context, isDarkMode),
            const SizedBox(height: AppTheme.cardPadding),
          ],
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

    // For BTC → EVM swaps, "Waiting for Deposit" should show as "Processing"
    // since Arkade handles the payment automatically
    final effectiveStatus =
        status == SwapStatusSimple.waitingForDeposit && widget.sourceToken.isBtc
            ? SwapStatusSimple.processing
            : status;

    switch (effectiveStatus) {
      case SwapStatusSimple.waitingForDeposit:
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange;
        statusText = 'Waiting for Deposit';
        break;
      case SwapStatusSimple.processing:
        icon = Icons.sync_rounded;
        color = AppTheme.colorBitcoin;
        statusText = 'Processing';
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: color),
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
    // Format amounts based on token type
    String formatAmount(SwapToken token, String amount) {
      if (token.isBtc) {
        return '$amount BTC';
      } else if (token.isStablecoin) {
        return '\$$amount';
      } else {
        // Non-stablecoin (XAUT, etc.) - show amount with symbol
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
                TokenIcon(token: widget.sourceToken, size: 40),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                      ),
                      Text(
                        '${widget.sourceToken.symbol} (${widget.sourceToken.network})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatAmount(widget.sourceToken, widget.sourceAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            // Divider with arrow
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTheme.elementSpacing),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
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
                    child: Container(
                      height: 1,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            // To
            Row(
              children: [
                TokenIcon(token: widget.targetToken, size: 40),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                      ),
                      Text(
                        '${widget.targetToken.symbol} (${widget.targetToken.network})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatAmount(widget.targetToken, widget.targetAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
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
                  isLightningInvoice
                      ? Icons.bolt_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: AppTheme.colorBitcoin,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isLightningInvoice
                      ? 'Pay Lightning Invoice'
                      : 'Send to Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // QR Code
            Center(
              child: GestureDetector(
                onTap: () => _copyToClipboard(depositAddress),
                child: CustomPaint(
                  foregroundPainter:
                      isDarkMode ? BorderPainter() : BorderPainterBlack(),
                  child: Container(
                    margin: const EdgeInsets.all(AppTheme.elementSpacing),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.cardRadiusBigger,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.elementSpacing),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: PrettyQrView.data(
                          data: depositAddress,
                          decoration: const PrettyQrDecoration(
                            shape: PrettyQrSmoothSymbol(roundFactor: 1),
                          ),
                          errorCorrectLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
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

  /// Build WalletConnect claim section for Ethereum swaps
  Widget _buildWalletConnectClaimSection(
      BuildContext context, bool isDarkMode) {
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
                  Icons.info_outline,
                  color: AppTheme.colorBitcoin,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Claim Your ${widget.targetToken.symbol}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your swap is ready! Connect your Ethereum wallet to claim your tokens. '
              'You will need to pay gas fees for the claim transaction.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // WalletConnect button
            WalletConnectButton(
              chain: EvmChain.ethereum,
              onConnected: () {},
            ),
            if (_walletService.isConnected) ...[
              const SizedBox(height: AppTheme.cardPadding),
              LongButtonWidget(
                title:
                    _isClaimingWalletConnect ? 'Claiming...' : 'Claim Tokens',
                customWidth: double.infinity,
                state: _isClaimingWalletConnect
                    ? ButtonState.loading
                    : ButtonState.idle,
                onTap: _isClaimingWalletConnect ? null : _claimViaWalletConnect,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Claim using WalletConnect (for Ethereum targets)
  Future<void> _claimViaWalletConnect() async {
    if (!_walletService.isConnected) {
      return;
    }

    setState(() => _isClaimingWalletConnect = true);

    try {
      // Use Gelato claim but with WalletConnect signature
      // The service will detect Ethereum and use the appropriate method
      await _swapService.claimGelato(widget.swapId);
      logger.i('Ethereum claim submitted for swap ${widget.swapId}');

      // Track swap transaction for analytics
      if (_swapInfo != null) {
        await AnalyticsService().trackSwapTransaction(
          amountSats: _swapInfo!.sourceAmountSats.toInt(),
          fromAsset: _swapInfo!.sourceToken,
          toAsset: _swapInfo!.targetToken,
          swapId: widget.swapId,
        );
      }

      setState(() {
        _showWalletConnectClaim = false;
      });
    } catch (e) {
      logger.e('Failed to claim via WalletConnect: $e');
      if (mounted) {
        OverlayService().showError('Failed to claim: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isClaimingWalletConnect = false);
      }
    }
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
              _swapInfo!.isBtcToEvm
                  ? 'BTC → ${widget.targetToken.symbol} (${widget.targetToken.network})'
                  : '${widget.sourceToken.symbol} (${widget.sourceToken.network}) → BTC',
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
      // Handle format like "2025-12-21 19:04:15.0 +00:00:00"
      String normalizedTimestamp = timestamp;

      // Remove the unusual timezone format (+00:00:00 or -00:00:00)
      if (timestamp.contains(' +') || timestamp.contains(' -')) {
        final parts = timestamp.split(RegExp(r' [+-]'));
        if (parts.isNotEmpty) {
          normalizedTimestamp = parts[0].trim();
        }
      }

      // Replace space between date and time with 'T' for ISO format
      normalizedTimestamp = normalizedTimestamp.replaceFirst(' ', 'T');

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
      return timestamp;
    }
  }
}
