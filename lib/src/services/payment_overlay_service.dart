import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to manage payment received overlays globally
class PaymentOverlayService {
  static final PaymentOverlayService _instance = PaymentOverlayService._internal();
  factory PaymentOverlayService() => _instance;
  PaymentOverlayService._internal();

  OverlayEntry? _currentOverlay;
  AnimationController? _animationController;

  /// Flag to suppress payment notifications during swap/send operations.
  /// When true, the global payment monitor should not show "payment received"
  /// notifications (e.g., when change from an outgoing tx is detected).
  bool _suppressPaymentNotifications = false;

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

  /// Global navigator key for overlay access
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Show a payment received overlay at the top of the screen
  Future<void> showPaymentReceivedOverlay({
    required BuildContext context,
    required PaymentReceived payment,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 4),
  }) async {
    // Remove any existing overlay
    hideOverlay();

    // Haptic feedback for success
    await HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context);

    // Create animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: overlay,
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    ));

    _currentOverlay = OverlayEntry(
      builder: (context) => _PaymentReceivedOverlayWidget(
        payment: payment,
        animation: offsetAnimation,
        onDismiss: () {
          hideOverlay();
          onDismiss?.call();
        },
      ),
    );

    overlay.insert(_currentOverlay!);
    _animationController!.forward();

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      hideOverlay();
      onDismiss?.call();
    });
  }

  /// Show a simple success overlay
  Future<void> showSuccessOverlay({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) async {
    hideOverlay();

    await HapticFeedback.lightImpact();

    final overlay = Overlay.of(context);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: overlay,
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));

    _currentOverlay = OverlayEntry(
      builder: (context) => _SimpleOverlayWidget(
        message: message,
        color: AppTheme.successColor,
        animation: offsetAnimation,
      ),
    );

    overlay.insert(_currentOverlay!);
    _animationController!.forward();

    Future.delayed(duration, hideOverlay);
  }

  /// Show an error overlay
  Future<void> showErrorOverlay({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) async {
    hideOverlay();

    await HapticFeedback.heavyImpact();

    final overlay = Overlay.of(context);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: overlay,
    );

    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));

    _currentOverlay = OverlayEntry(
      builder: (context) => _SimpleOverlayWidget(
        message: message,
        color: AppTheme.errorColor,
        animation: offsetAnimation,
      ),
    );

    overlay.insert(_currentOverlay!);
    _animationController!.forward();

    Future.delayed(duration, hideOverlay);
  }

  /// Hide the current overlay
  void hideOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _animationController?.dispose();
    _animationController = null;
  }
}

/// Payment received overlay widget with transaction details
class _PaymentReceivedOverlayWidget extends StatelessWidget {
  final PaymentReceived payment;
  final Animation<Offset> animation;
  final VoidCallback onDismiss;

  const _PaymentReceivedOverlayWidget({
    required this.payment,
    required this.animation,
    required this.onDismiss,
  });

  String _formatAmount(BigInt sats) {
    final amount = sats.toInt();
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(8)} BTC';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M sats';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k sats';
    }
    return '$amount sats';
  }

  String _truncateTxid(String txid) {
    if (txid.length <= 16) return txid;
    return '${txid.substring(0, 8)}...${txid.substring(txid.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
              onDismiss();
            }
          },
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.successColor,
                    AppTheme.successColorGradient,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadiusBig),
                  bottomRight: Radius.circular(AppTheme.borderRadiusBig),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with icon and title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.elementSpacing / 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: AppTheme.cardPadding,
                        ),
                      ),
                      const SizedBox(width: AppTheme.elementSpacing),
                      Text(
                        l10n?.paymentReceived ?? 'Payment Received!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  // Amount display
                  GlassContainer(
                    opacity: 0.15,
                    customColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                      vertical: AppTheme.elementSpacing,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${_formatAmount(payment.amountSats)}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _truncateTxid(payment.txid),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: AppTheme.cardPadding * 1.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing / 2),
                  Text(
                    'Tap to dismiss',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple text overlay widget
class _SimpleOverlayWidget extends StatelessWidget {
  final String message;
  final Color color;
  final Animation<Offset> animation;

  const _SimpleOverlayWidget({
    required this.message,
    required this.color,
    required this.animation,
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
    );
  }
}
