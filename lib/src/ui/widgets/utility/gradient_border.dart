import 'package:flutter/material.dart';

class GradientBoxBorder extends BoxBorder {
  final BorderRadius borderRadius;
  final double borderWidth;
  final bool isTransparent;
  final bool isLightTheme;

  const GradientBoxBorder({
    this.borderRadius = const BorderRadius.all(Radius.circular(14.0)),
    this.borderWidth = 1.5,
    this.isTransparent = false,
    this.isLightTheme = false,
  }) : super();

  @override
  BoxBorder? add(ShapeBorder other, {bool reversed = false}) => null;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect).deflate(borderWidth));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect));
  }

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
    TextDirection? textDirection,
  }) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isTransparent
            ? [
                Colors.transparent,
                Colors.transparent,
                Colors.transparent,
                Colors.transparent,
              ]
            : isLightTheme
                ? [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.15),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.2),
                  ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final outer = this.borderRadius.toRRect(rect);
    canvas.drawRRect(outer, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;
}
