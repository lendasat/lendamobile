import 'dart:io' show Platform;
import 'package:ark_flutter/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a bottom sheet with smooth spring animations for a premium feel.
///
/// Features:
/// - Spring-based animations (snappy like iOS)
/// - Smooth barrier fade
/// - iOS edge swipe to dismiss (doesn't conflict with scroll views)
/// - RepaintBoundary for performance
Future<T?> arkBottomSheet<T>({
  required BuildContext context,
  double borderRadius = 20.0,
  required Widget child,
  double? height,
  double? width,
  Color backgroundColor = Colors.transparent,
  bool isDismissible = true,
  bool isScrollControlled = true,
  bool enableDrag = true,
}) {
  final screenSize = MediaQuery.sizeOf(context);

  return Navigator.of(context, rootNavigator: true).push<T>(
    _SmoothBottomSheetRoute<T>(
      builder: (context) => ArkBottomSheetWidget(
        height: height,
        width: width,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        child: child,
      ),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      constraints: BoxConstraints(
        maxHeight: height ?? screenSize.height * 0.9,
        maxWidth: width ?? screenSize.width,
      ),
      borderRadius: borderRadius,
    ),
  );
}

/// Custom modal route with spring animation for smooth bottom sheets
class _SmoothBottomSheetRoute<T> extends PopupRoute<T> {
  _SmoothBottomSheetRoute({
    required this.builder,
    required this.isDismissible,
    required this.enableDrag,
    required this.isScrollControlled,
    required this.constraints,
    required this.borderRadius,
  });

  final WidgetBuilder builder;
  final bool isDismissible;
  final bool enableDrag;
  final bool isScrollControlled;
  final BoxConstraints constraints;
  final double borderRadius;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  // Snappy spring animation - fast response, slight overshoot
  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  AnimationController createAnimationController() {
    return AnimationController(
      vsync: navigator!,
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Spring curve for snappy, natural feel
    const springCurve = _SnappySpringCurve();
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: springCurve,
      reverseCurve: Curves.easeOutCubic,
    );

    return Stack(
      children: [
        // Barrier with fade animation
        GestureDetector(
          onTap: isDismissible ? () => Navigator.of(context).pop() : null,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: Container(color: barrierColor),
          ),
        ),
        // Bottom sheet with slide + fade animation
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: constraints,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: _DraggableBottomSheet(
                    enableDrag: enableDrag,
                    animationController: controller!,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Draggable wrapper that allows pulling down to dismiss
class _DraggableBottomSheet extends StatefulWidget {
  const _DraggableBottomSheet({
    required this.enableDrag,
    required this.animationController,
    required this.child,
  });

  final bool enableDrag;
  final AnimationController animationController;
  final Widget child;

  @override
  State<_DraggableBottomSheet> createState() => _DraggableBottomSheetState();
}

class _DraggableBottomSheetState extends State<_DraggableBottomSheet> {
  double _dragExtent = 0;
  bool _isDragging = false;

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enableDrag) return;
    _isDragging = true;
    _dragExtent = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    _dragExtent += details.primaryDelta ?? 0;
    if (_dragExtent < 0) _dragExtent = 0;

    // Update animation value based on drag
    final screenHeight = MediaQuery.sizeOf(context).height;
    final progress = _dragExtent / (screenHeight * 0.4);
    widget.animationController.value = (1.0 - progress).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Dismiss if dragged far enough or with enough velocity
    if (_dragExtent > screenHeight * 0.15 || velocity > 500) {
      // Haptic feedback on dismiss
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } else {
      // Snap back with spring animation
      widget.animationController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
    _dragExtent = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

/// Custom spring curve for snappy, iOS-like animations
class _SnappySpringCurve extends Curve {
  const _SnappySpringCurve();

  @override
  double transformInternal(double t) {
    // Custom spring formula for snappy feel
    // Fast initial movement, slight overshoot, quick settle
    final damping = 0.7;
    final frequency = 3.5;

    if (t == 0.0 || t == 1.0) return t;

    final omega = frequency * 2 * 3.14159;
    final decay = damping * omega;

    return 1.0 -
        (1.0 + decay * t / omega) *
            _exp(-decay * t) *
            _cos(omega * _sqrt(1 - damping * damping) * t);
  }

  double _exp(double x) => x < -20 ? 0.0 : (x > 20 ? 485165195.4 : _fastExp(x));
  double _cos(double x) => _fastCos(x);
  double _sqrt(double x) => x <= 0 ? 0 : _fastSqrt(x);

  // Fast approximations
  double _fastExp(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 12; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  double _fastCos(double x) {
    x = x % (2 * 3.14159);
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _fastSqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 5; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

class ArkBottomSheetWidget extends StatefulWidget {
  const ArkBottomSheetWidget({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 20.0,
    this.backgroundColor = Colors.transparent,
    required this.child,
  });

  final double borderRadius;
  final double? height;
  final double? width;
  final Color backgroundColor;
  final Widget child;

  @override
  State<ArkBottomSheetWidget> createState() => _ArkBottomSheetWidgetState();
}

class _ArkBottomSheetWidgetState extends State<ArkBottomSheetWidget> {
  static const double _dismissThreshold = 100.0; // Must drag 100px to dismiss

  void _handleEdgeSwipeDismiss() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Cache theme lookup to avoid multiple calls
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final surfaceColor = widget.backgroundColor != Colors.transparent
        ? widget.backgroundColor
        : theme.colorScheme.surface;

    final topRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.borderRadius),
      topRight: Radius.circular(widget.borderRadius),
    );

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.elementSpacing),
        // Drag handle
        Container(
          height: AppTheme.elementSpacing / 1.375,
          width: AppTheme.cardPadding * 2.25,
          decoration: BoxDecoration(
            color: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCircular),
          ),
        ),
        const SizedBox(height: AppTheme.elementSpacing * 0.75),
        Flexible(
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: topRadius,
              // Performance: Reduced blur radius and only apply shadow in dark mode
              boxShadow: isLight
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: topRadius,
              // Performance: Wrap child in RepaintBoundary to isolate repaints
              child: RepaintBoundary(child: widget.child),
            ),
          ),
        ),
      ],
    );

    // Only add iOS edge swipe gesture on iOS - uses RawGestureDetector
    // to avoid conflicts with child scroll views
    if (Platform.isIOS) {
      return RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          _EdgeSwipeGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<_EdgeSwipeGestureRecognizer>(
            () => _EdgeSwipeGestureRecognizer(
              onDismiss: _handleEdgeSwipeDismiss,
              dismissThreshold: _dismissThreshold,
            ),
            (_EdgeSwipeGestureRecognizer instance) {},
          ),
        },
        child: content,
      );
    }

    return content;
  }
}

/// Custom gesture recognizer for iOS edge swipe to dismiss.
/// Only accepts horizontal drags starting from the left edge,
/// immediately rejects otherwise so child scroll views can handle the gesture.
class _EdgeSwipeGestureRecognizer extends HorizontalDragGestureRecognizer {
  _EdgeSwipeGestureRecognizer({
    required this.onDismiss,
    this.edgeThreshold = 40.0,
    this.dismissThreshold = 100.0,
  });

  final VoidCallback onDismiss;
  final double edgeThreshold;
  final double dismissThreshold;

  double _dragDistance = 0;
  bool _isValidEdgeSwipe = false;

  @override
  void addPointer(PointerDownEvent event) {
    // Only accept if pointer starts within edge threshold from left
    if (event.position.dx < edgeThreshold) {
      _isValidEdgeSwipe = true;
      _dragDistance = 0;
      super.addPointer(event);
    }
    // Don't call super - this rejects the gesture immediately,
    // allowing child scroll views to handle it
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_isValidEdgeSwipe) return;

    if (event is PointerMoveEvent) {
      _dragDistance += event.delta.dx;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_dragDistance > dismissThreshold) {
        onDismiss();
      }
      _isValidEdgeSwipe = false;
      _dragDistance = 0;
    }

    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _isValidEdgeSwipe = false;
    _dragDistance = 0;
    super.rejectGesture(pointer);
  }

  @override
  String get debugDescription => 'edge swipe';
}
