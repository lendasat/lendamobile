import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Service to manage payment received overlays globally
class PaymentOverlayService {
  static final PaymentOverlayService _instance =
      PaymentOverlayService._internal();
  factory PaymentOverlayService() => _instance;
  PaymentOverlayService._internal();

  /// Flag to suppress payment notifications during swap/send operations.
  /// When true, the global payment monitor should not show "payment received"
  /// notifications (e.g., when change from an outgoing tx is detected).
  bool _suppressPaymentNotifications = false;

  /// Track recently shown payments to prevent duplicates
  String? _lastShownPaymentTxid;
  DateTime? _lastShownPaymentTime;

  /// Whether payment notifications are currently suppressed.
  bool get suppressPaymentNotifications => _suppressPaymentNotifications;

  /// Suppress payment notifications (call when starting a swap or send).
  void startSuppression() {
    _suppressPaymentNotifications = true;
  }

  /// Stop suppressing payment notifications (call when swap/send completes).
  void stopSuppression() {
    _suppressPaymentNotifications = false;
  }

  /// Check if this payment was recently shown (deduplication)
  bool _isRecentlyShown(String txid) {
    if (_lastShownPaymentTxid == txid && _lastShownPaymentTime != null) {
      final elapsed = DateTime.now().difference(_lastShownPaymentTime!);
      // Don't show the same payment within 10 seconds
      if (elapsed.inSeconds < 10) {
        return true;
      }
    }
    return false;
  }

  /// Mark a payment as shown
  void _markAsShown(String txid) {
    _lastShownPaymentTxid = txid;
    _lastShownPaymentTime = DateTime.now();
  }

  /// Show a payment received bottom sheet
  Future<void> showPaymentReceivedBottomSheet({
    required BuildContext context,
    required PaymentReceived payment,
    double? bitcoinPrice,
    VoidCallback? onDismiss,
  }) async {
    // Deduplicate - don't show the same payment twice within 10 seconds
    if (_isRecentlyShown(payment.txid)) {
      return;
    }
    _markAsShown(payment.txid);

    // Haptic feedback for success
    await HapticFeedback.mediumImpact();

    await arkBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      child: _PaymentReceivedBottomSheetContent(
        payment: payment,
        bitcoinPrice: bitcoinPrice,
        onDismiss: onDismiss,
      ),
    );

    // Call onDismiss when bottom sheet is closed
    onDismiss?.call();
  }

  /// Show a simple success overlay
  Future<void> showSuccessOverlay({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) async {
    await HapticFeedback.lightImpact();

    final overlayState = Overlay.of(context);

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: overlayState,
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    bool isDismissed = false;

    late final OverlayEntry overlay;

    void dismiss() {
      if (isDismissed) return;
      isDismissed = true;
      overlay.remove();
      animationController.dispose();
    }

    overlay = OverlayEntry(
      builder: (context) => _SimpleOverlayWidget(
        message: message,
        color: AppTheme.successColor,
        animation: offsetAnimation,
        onDismiss: dismiss,
      ),
    );

    overlayState.insert(overlay);
    animationController.forward();

    Future.delayed(duration, dismiss);
  }

  /// Show an error overlay
  Future<void> showErrorOverlay({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) async {
    await HapticFeedback.heavyImpact();

    final overlayState = Overlay.of(context);

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: overlayState,
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    bool isDismissed = false;

    late final OverlayEntry overlay;

    void dismiss() {
      if (isDismissed) return;
      isDismissed = true;
      overlay.remove();
      animationController.dispose();
    }

    overlay = OverlayEntry(
      builder: (context) => _SimpleOverlayWidget(
        message: message,
        color: AppTheme.errorColor,
        animation: offsetAnimation,
        onDismiss: dismiss,
      ),
    );

    overlayState.insert(overlay);
    animationController.forward();

    Future.delayed(duration, dismiss);
  }
}

/// Payment received bottom sheet content widget
class _PaymentReceivedBottomSheetContent extends StatefulWidget {
  final PaymentReceived payment;
  final double? bitcoinPrice;
  final VoidCallback? onDismiss;

  const _PaymentReceivedBottomSheetContent({
    required this.payment,
    this.bitcoinPrice,
    this.onDismiss,
  });

  @override
  State<_PaymentReceivedBottomSheetContent> createState() =>
      _PaymentReceivedBottomSheetContentState();
}

class _PaymentReceivedBottomSheetContentState
    extends State<_PaymentReceivedBottomSheetContent> {
  String _formatAmount(int sats) {
    // Format with thousands separator
    final formatted = sats.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currencyService = context.watch<CurrencyPreferenceService>();
    final showCoinBalance = currencyService.showCoinBalance;

    final amountSats = widget.payment.amountSats.toInt();
    final amountBtc = amountSats / BitcoinConstants.satsPerBtc;
    // Use provided price, or fall back to global cache
    final btcPrice = widget.bitcoinPrice ?? BitcoinPriceCache.currentPrice ?? 0;
    final amountUsd = amountBtc * btcPrice;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTheme.cardPadding),
          // Bani image
          SizedBox(
            width: 160,
            height: 160,
            child: Image.asset(
              'assets/images/bani/bani_receive_bitcoin.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding * 1.5),
          // Title
          Text(
            l10n?.paymentReceived ?? 'Payment Received!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Amount display (tappable to toggle between sats and fiat)
          GestureDetector(
            onTap: () => currencyService.toggleShowCoinBalance(),
            behavior: HitTestBehavior.opaque,
            child: (showCoinBalance || btcPrice == 0)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+${_formatAmount(amountSats)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        AppTheme.satoshiIcon,
                        size: 32,
                        color: AppTheme.successColor,
                      ),
                    ],
                  )
                : Text(
                    '+${currencyService.formatAmount(amountUsd)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.successColor,
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.cardPadding * 2),
          // Back to wallet button
          LongButtonWidget(
            title: l10n?.backToWallet ?? 'Back to Wallet',
            buttonType: ButtonType.transparent,
            customWidth: double.infinity,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppTheme.cardPadding),
        ],
      ),
    );
  }
}

/// Simple text overlay widget
class _SimpleOverlayWidget extends StatelessWidget {
  final String message;
  final Color color;
  final Animation<Offset> animation;
  final VoidCallback onDismiss;

  const _SimpleOverlayWidget({
    required this.message,
    required this.color,
    required this.animation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: animation,
        child: GestureDetector(
          onTap: onDismiss,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: EdgeInsets.only(
                top: topPadding + AppTheme.elementSpacing,
                bottom: AppTheme.cardPadding,
                left: AppTheme.cardPadding,
                right: AppTheme.cardPadding,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadiusBig),
                  bottomRight: Radius.circular(AppTheme.borderRadiusBig),
                ),
              ),
              child: Center(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: darken(color, 80),
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
