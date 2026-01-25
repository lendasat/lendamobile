import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/swap_monitoring_service.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart' as lendaswap_api;
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
  bool _isRefunding = false;

  /// Get the target EVM chain for claiming tokens
  EvmChain get _targetEvmChain {
    final chainId = widget.targetToken.chainId.toLowerCase();
    if (chainId.contains('ethereum') || chainId == 'eth') {
      return EvmChain.ethereum;
    }
    return EvmChain.polygon;
  }

  @override
  void initState() {
    super.initState();
    // Register that we're viewing this swap (prevents bottom sheet notification)
    PaymentOverlayService().setCurrentlyViewedSwap(widget.swapId);
    // Tell the monitoring service to watch this swap
    _swapMonitor.startMonitoringSwap(widget.swapId);
    _loadSwapInfo();
    _startPolling();
    _listenToClaimEvents();
  }

  @override
  void dispose() {
    // Unregister swap viewing
    PaymentOverlayService().setCurrentlyViewedSwap(null);
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
          // EXCEPTION: Loan repayment swaps should stay to auto-mark installment as paid
          if (widget.sourceToken.isBtc &&
              !_swapMonitor.requiresWalletConnect(swap) &&
              widget.loanContractId == null) {
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

  /// Format a duration in seconds to a human-readable string.
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '${minutes}m ${secs}s' : '$minutes minutes';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '$hours hours';
    }
  }

  /// Check if the refund locktime has passed.
  /// Returns true if refund is available, false otherwise.
  bool _isRefundLocktimePassed() {
    if (_swapInfo?.refundLocktime == null) return true; // No locktime = allow
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= _swapInfo!.refundLocktime!;
  }

  /// Get remaining time until refund is available.
  /// Returns null if refund is already available.
  int? _getRefundTimeRemaining() {
    if (_swapInfo?.refundLocktime == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = _swapInfo!.refundLocktime! - now;
    return remaining > 0 ? remaining : null;
  }

  /// Handle the refund button tap.
  /// Routes to appropriate refund method based on swap direction.
  Future<void> _handleRefund() async {
    if (_swapInfo == null || !_swapInfo!.canRefund) return;

    // Check if locktime has passed
    if (!_isRefundLocktimePassed()) {
      final remaining = _getRefundTimeRemaining();
      if (remaining != null) {
        OverlayService().showError(
          'Refund available in ${_formatDuration(remaining)}',
        );
        return;
      }
    }

    // Check if this is an EVM→BTC swap (requires web interface)
    if (_swapService.requiresWebRefund(_swapInfo!)) {
      await _showEvmRefundInfoSheet();
      return;
    }

    // BTC→EVM swap - can refund directly from mobile via VHTLC
    if (_swapService.canRefundFromMobile(_swapInfo!)) {
      final refundAddress = await _showRefundAddressSheet();
      if (refundAddress == null || refundAddress.isEmpty) return;

      setState(() => _isRefunding = true);

      try {
        final txid =
            await _swapService.refundVhtlc(widget.swapId, refundAddress);
        if (mounted) {
          OverlayService()
              .showSuccess('Refund initiated: ${_truncateId(txid)}');
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
  }

  /// Show a bottom sheet to collect the refund address.
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

  /// Show info sheet for EVM→BTC refunds that require web interface.
  Future<void> _showEvmRefundInfoSheet() async {
    await arkBottomSheet(
      context: context,
      child: _EvmRefundInfoSheet(
        swapId: widget.swapId,
        onOpenWeb: () async {
          Navigator.pop(context);
          // Open LendaSwap web interface
          final url = Uri.parse('https://lendaswap.lendasat.com');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            OverlayService().showError('Could not open web browser');
          }
        },
      ),
    );
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
      body: _errorMessage != null
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
    // Show loading spinner when still loading swap info
    if (_isLoading) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.colorBitcoin.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          Text(
            'Loading...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colorBitcoin,
                ),
          ),
        ],
      );
    }

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
                  color: isDarkMode ? Colors.white : Colors.black,
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
                    margin: const EdgeInsets.all(AppTheme.cardPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.cardRadiusBigger,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppTheme.cardPadding / 1.25),
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
              'Your swap is ready! Connect your ${_targetEvmChain.name} wallet to claim your tokens. '
              'You will need to pay gas fees for the claim transaction.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // WalletConnect button
            WalletConnectButton(
              chain: _targetEvmChain,
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

  /// Claim using WalletConnect (for Ethereum targets).
  ///
  /// This calls claimSwap(swapId, secret) on the HTLC contract via WalletConnect.
  /// The user pays gas fees for the transaction.
  Future<void> _claimViaWalletConnect() async {
    if (!_walletService.isConnected) {
      OverlayService().showError('Please connect your wallet first');
      return;
    }

    setState(() => _isClaimingWalletConnect = true);

    try {
      // Ensure wallet is on the correct chain (Ethereum) before claiming
      logger.i('Ensuring wallet is on ${_targetEvmChain.name} chain');
      await _walletService.ensureCorrectChain(_targetEvmChain);

      // Get HTLC claim data from Rust SDK
      logger.i('Getting HTLC claim data for swap ${widget.swapId}');
      final claimData =
          await lendaswap_api.lendaswapGetHtlcClaimData(swapId: widget.swapId);

      logger.i(
          'Calling claimSwap on HTLC contract ${claimData.htlcAddress} via WalletConnect');

      // Send the claim transaction via WalletConnect
      final txHash = await _walletService.sendTransaction(
        to: claimData.htlcAddress,
        data: claimData.calldata,
      );

      logger.i('Ethereum claim transaction sent: $txHash');
      OverlayService().showSuccess('Claim transaction sent!');

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

      // The swap monitoring will pick up the completion
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
              Builder(builder: (context) {
                final remaining = _getRefundTimeRemaining();
                final isLocked = remaining != null;

                String buttonTitle;
                if (_isRefunding) {
                  buttonTitle = 'Refunding...';
                } else if (isLocked) {
                  buttonTitle = 'Refund in ${_formatDuration(remaining)}';
                } else {
                  buttonTitle = 'Refund';
                }

                return LongButtonWidget(
                  title: buttonTitle,
                  buttonType: ButtonType.secondary,
                  state: _isRefunding
                      ? ButtonState.loading
                      : (isLocked ? ButtonState.disabled : ButtonState.idle),
                  onTap: (_isRefunding || isLocked) ? null : _handleRefund,
                );
              }),
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

/// Bottom sheet widget for collecting refund address.
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
              const Icon(
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

/// Bottom sheet widget explaining EVM→BTC refunds require web interface.
class _EvmRefundInfoSheet extends StatelessWidget {
  final String swapId;
  final VoidCallback onOpenWeb;

  const _EvmRefundInfoSheet({
    required this.swapId,
    required this.onOpenWeb,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Refund via Web',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
          Text(
            'This swap requires you to sign a transaction with your EVM wallet (e.g., MetaMask) to refund your stablecoins.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Text(
            'Please use the LendaSwap web interface to complete your refund:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Steps to refund:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  _buildStep(context, '1', 'Go to lendaswap.lendasat.com'),
                  _buildStep(context, '2', 'Connect the same wallet you used'),
                  _buildStep(context, '3', 'Find this swap in your history'),
                  _buildStep(context, '4', 'Click "Refund" when available'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note: Refund becomes available after the timelock expires.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
          LongButtonWidget(
            title: 'Open Web Interface',
            customWidth: double.infinity,
            onTap: onOpenWeb,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: 'Close',
            buttonType: ButtonType.secondary,
            customWidth: double.infinity,
            onTap: () => Navigator.pop(context),
          ),
          SafeArea(
            top: false,
            child: const SizedBox(height: AppTheme.cardPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
