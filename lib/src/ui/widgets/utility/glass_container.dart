import 'package:flutter/material.dart';
import 'package:ark_flutter/theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final dynamic
      borderRadius; // Support both double and BorderRadius for compatibility
  final double? height;
  final double? width;
  final double borderThickness;
  final List<BoxShadow>? customShadow;
  final Color? customColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double blurX;
  final double blurY;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 50,
    this.opacity = 0.1,
    this.borderRadius,
    this.height,
    this.width,
    this.borderThickness = 1,
    this.customShadow,
    this.customColor,
    this.margin,
    this.padding,
    this.blurX = 5,
    this.blurY = 5,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    // Handle dynamic borderRadius - support both double and BorderRadius for backward compatibility
    BorderRadius radius;
    if (borderRadius == null) {
      radius = const BorderRadius.all(
        Radius.circular(AppTheme.cardPadding * 2.5 / 3),
      ); // Original default
    } else if (borderRadius is double) {
      radius = BorderRadius.circular(borderRadius);
    } else if (borderRadius is BorderRadius) {
      radius = borderRadius;
    } else {
      // Fallback for any other type
      radius = const BorderRadius.all(
        Radius.circular(AppTheme.cardPadding * 2.5 / 3),
      );
    }

    // Performance optimization: use RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          // Performance optimization: only apply shadows when needed
          boxShadow: customShadow != null
              ? customShadow!
              : boxShadow != null
                  ? boxShadow!
                  : Theme.of(context).brightness == Brightness.light
                      ? [] // No shadows in light mode
                      : [AppTheme.boxShadowSuperSmall], // Minimal shadow in dark mode
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              // Simplified color calculation for better performance
              color: customColor ??
                  (Theme.of(context).brightness == Brightness.light
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: opacity)),
              borderRadius: radius,
              // border: border,
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
