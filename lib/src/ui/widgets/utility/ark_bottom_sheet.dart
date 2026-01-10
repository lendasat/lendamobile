import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

Future<T?> arkBottomSheet<T>({
  required BuildContext context,
  double borderRadius = 20.0,
  required Widget child,
  double? height,
  double? width,
  Color backgroundColor = Colors.transparent,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  // Performance: Use MediaQuery.sizeOf instead of MediaQuery.of to only
  // subscribe to size changes, not viewInsets (keyboard) changes.
  // This prevents rebuilds when keyboard opens/closes.
  final screenSize = MediaQuery.sizeOf(context);

  return showModalBottomSheet(
    context: context,
    elevation: 0.0,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
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

class ArkBottomSheetWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Cache theme lookup to avoid multiple calls
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final surfaceColor = backgroundColor != Colors.transparent
        ? backgroundColor
        : theme.colorScheme.surface;

    final topRadius = BorderRadius.only(
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
    );

    return Column(
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
            height: height,
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
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      ],
    );
  }
}
