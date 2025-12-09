import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

class SolidContainer extends StatelessWidget {
  final List<Color> gradientColors;
  final double height;
  final double width;
  final AlignmentGeometry alignment;
  final double borderRadius;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final bool normalPainter;
  final double borderWidth;
  final Widget child;

  SolidContainer({
    super.key,
    List<Color>? gradientColors,
    double? height,
    double? width,
    AlignmentGeometry? alignment,
    double? borderRadius,
    AlignmentGeometry? gradientBegin,
    AlignmentGeometry? gradientEnd,
    this.normalPainter = true,
    this.borderWidth = 1.5,
    required this.child,
  })  : gradientColors = gradientColors ??
            [AppTheme.colorBitcoin, AppTheme.colorPrimaryGradient],
        height = height ?? AppTheme.cardPadding * 1.5,
        width = width ?? AppTheme.cardPadding * 2.5,
        alignment = alignment ?? Alignment.center,
        borderRadius = borderRadius ?? AppTheme.borderRadiusMid,
        gradientBegin = gradientBegin ?? Alignment.topCenter,
        gradientEnd = gradientEnd ?? Alignment.bottomCenter;

  @override
  Widget build(BuildContext context) {
    final bool useBitcoinGradient =
        gradientColors.contains(AppTheme.colorBitcoin) &&
            gradientColors.contains(AppTheme.colorPrimaryGradient);

    return CustomPaint(
      child: Container(
        height: height,
        width: width,
        alignment: alignment,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: useBitcoinGradient
              ? null
              : Theme.of(context).colorScheme.primary,
          gradient: useBitcoinGradient
              ? LinearGradient(
                  begin: gradientBegin,
                  end: gradientEnd,
                  colors: gradientColors,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}
