import 'dart:io' show Platform;
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet with optimized animations for a snappy feel.
///
/// Performance optimizations:
/// - Uses `useSafeArea` to reduce layout calculations
/// - Subtle barrier color for smoother appearance
/// - `RepaintBoundary` on child content
/// - Cached theme lookups
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
  // Performance: Use MediaQuery.sizeOf instead of MediaQuery.of to only
  // subscribe to size changes, not viewInsets (keyboard) changes.
  final screenSize = MediaQuery.sizeOf(context);

  return showModalBottomSheet(
    context: context,
    elevation: 0.0,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    useSafeArea: true,
    // Subtle barrier - less jarring appearance/disappearance
    barrierColor: Colors.black54,
    constraints: BoxConstraints(
      maxHeight: height ?? screenSize.height * 0.9,
      maxWidth: width ?? screenSize.width,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
    ),
    builder: (context) {
      return Material(
        color: Colors.transparent,
        child: ArkBottomSheetWidget(
          height: height,
          width: width,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          child: child,
        ),
      );
    },
  );
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
  double _dragStartX = 0;
  double _dragDistance = 0;
  static const double _edgeThreshold =
      40.0; // Start drag must be within 40px of left edge
  static const double _dismissThreshold = 100.0; // Must drag 100px to dismiss
  bool _isDraggingFromEdge = false;

  void _onHorizontalDragStart(DragStartDetails details) {
    // Only handle edge swipes on iOS
    if (!Platform.isIOS) return;

    _dragStartX = details.globalPosition.dx;
    // Check if drag started from left edge
    _isDraggingFromEdge = _dragStartX < _edgeThreshold;
    _dragDistance = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingFromEdge) return;

    _dragDistance += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDraggingFromEdge) return;

    // If dragged far enough to the right, dismiss
    if (_dragDistance > _dismissThreshold) {
      Navigator.of(context).pop();
    }

    _isDraggingFromEdge = false;
    _dragDistance = 0;
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

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTheme.elementSpacing),
          // Drag handle
          Container(
            height: AppTheme.elementSpacing / 1.375,
            width: AppTheme.cardPadding * 2.25,
            decoration: BoxDecoration(
              color: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusCircular),
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
                          blurRadius: 4, // Reduced from 10
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
      ),
    );
  }
}
