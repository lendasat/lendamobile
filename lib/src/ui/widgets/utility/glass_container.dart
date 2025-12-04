import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';

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
    BorderRadius radius;
    if (borderRadius == null) {
      radius = const BorderRadius.all(
        Radius.circular(AppTheme.paddingL * 2.5 / 3),
      );
    } else if (borderRadius is double) {
      radius = BorderRadius.circular(borderRadius);
    } else if (borderRadius is BorderRadius) {
      radius = borderRadius;
    } else {
      radius = const BorderRadius.all(
        Radius.circular(AppTheme.paddingL * 2.5 / 3),
      );
    }

    final isLight = Theme.of(context).brightness == Brightness.light;

    final defaultBoxShadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 5,
    );

    final lightThemeShadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    );

    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          boxShadow: customShadow != null
              ? customShadow!
              : boxShadow != null
                  ? boxShadow!
                  : isLight
                      ? [lightThemeShadow]
                      : [defaultBoxShadow],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: customColor ??
                  (isLight
                      ? Colors.black.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: opacity)),
              borderRadius: radius,
              border: border ??
                  (isLight
                      ? Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                          width: 1,
                        )
                      : null),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
