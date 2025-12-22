import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global overlay service for displaying notification overlays
/// Replaces snackbars with a more visually appealing top overlay
class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  OverlayEntry? _currentOverlay;
  AnimationController? _currentAnimationController;

  /// Show a simple text overlay notification
  /// [message] - The message to display
  /// [color] - Background color (defaults to success green)
  Future<void> showOverlay(
    String? message, {
    Color color = AppTheme.successColor,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("No context found. Cannot display overlay.");
      return;
    }

    // Remove any existing overlay
    _removeCurrentOverlay();

    // Haptic feedback
    await HapticFeedback.lightImpact();

    final overlayState = Overlay.of(context);

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: overlayState,
    )..forward();

    _currentAnimationController = animationController;

    final offsetAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SlideTransition(
          position: offsetAnimation,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadiusBig),
                  bottomRight: Radius.circular(AppTheme.borderRadiusBig),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppTheme.cardPadding * 0.5,
                    horizontal: AppTheme.cardPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        color == AppTheme.errorColor
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: AppTheme.cardPadding,
                        color: darken(color, 70),
                      ),
                      const SizedBox(width: AppTheme.elementSpacing / 2),
                      Flexible(
                        child: Text(
                          message ?? 'Success!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: darken(color, 90),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlay);
    _currentOverlay = overlay;

    // Remove the overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentOverlay == overlay) {
        _removeCurrentOverlay();
      }
    });
  }

  /// Show success overlay (convenience method)
  Future<void> showSuccess(String message) async {
    await showOverlay(message, color: AppTheme.successColor);
  }

  /// Show error overlay (convenience method)
  Future<void> showError(String message) async {
    await showOverlay(message, color: AppTheme.errorColor);
  }

  /// Remove current overlay if any
  void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _currentAnimationController?.dispose();
    _currentAnimationController = null;
  }

  /// Manually remove any active overlay
  void removeOverlay() {
    _removeCurrentOverlay();
  }
}
