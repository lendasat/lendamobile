import 'package:flutter/material.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/scanning_bubbles.dart';

/// QR Scanner Overlay with cutout and corner borders
/// Ported from BitNet project
class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({
    super.key,
    this.overlayColour,
    this.borderColor,
    this.borderWidth = 5.5,
    this.borderRadius = 42.0,
    this.showBubbles = true,
  });

  final Color? overlayColour;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final bool showBubbles;

  @override
  Widget build(BuildContext context) {
    final scanArea =
        MediaQuery.of(context).size.width - AppTheme.cardPadding * 5;
    final effectiveOverlayColor =
        overlayColour ?? Colors.black.withValues(alpha: 0.5);

    return Stack(
      children: [
        // Overlay with cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            effectiveOverlayColor,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: scanArea,
                  width: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corner borders
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            foregroundPainter: QRBorderPainter(
              color: borderColor ?? Colors.white,
              strokeWidth: borderWidth,
            ),
            child: SizedBox(
              width: scanArea + AppTheme.cardPadding * 1.25,
              height: scanArea + AppTheme.cardPadding * 1.25,
            ),
          ),
        ),
        // Animated scanning bubbles
        if (showBubbles)
          Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: SizedBox(
                width: scanArea - AppTheme.cardPadding,
                height: scanArea - AppTheme.cardPadding,
                child: ScanningBubbles(
                  width: scanArea - AppTheme.cardPadding,
                  height: scanArea - AppTheme.cardPadding,
                  bubbleColor: Colors.white,
                  spawnIntervalMs: 200,
                  maxRadius: 8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the white corner borders around the scan area
class QRBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  QRBorderPainter({
    this.color = Colors.white,
    this.strokeWidth = 5.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = AppTheme.cardPaddingBigger * 1.5;
    const tRadius = 1.65 * radius;

    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth,
      size.width - 2 * strokeWidth,
      size.height - 2 * strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    // Clipping rectangles for corners only
    const clippingRect0 = Rect.fromLTWH(0, 0, tRadius, tRadius);
    final clippingRect1 = Rect.fromLTWH(
      size.width - tRadius,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect2 = Rect.fromLTWH(
      0,
      size.height - tRadius,
      tRadius,
      tRadius,
    );
    final clippingRect3 = Rect.fromLTWH(
      size.width - tRadius,
      size.height - tRadius,
      tRadius,
      tRadius,
    );

    final path = Path()
      ..addRect(clippingRect0)
      ..addRect(clippingRect1)
      ..addRect(clippingRect2)
      ..addRect(clippingRect3);

    canvas.clipPath(path);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant QRBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Smaller version of the border painter for buttons/icons
class QRBorderPainterSmall extends CustomPainter {
  final Color color;
  final double strokeWidth;

  QRBorderPainterSmall({
    this.color = Colors.white,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = AppTheme.cardPadding / 2;
    const tRadius = 3 * radius / 2;

    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth,
      size.width - 2 * strokeWidth,
      size.height - 2 * strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    const clippingRect0 = Rect.fromLTWH(0, 0, tRadius, tRadius);
    final clippingRect1 = Rect.fromLTWH(
      size.width - tRadius,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect2 = Rect.fromLTWH(
      0,
      size.height - tRadius,
      tRadius,
      tRadius,
    );
    final clippingRect3 = Rect.fromLTWH(
      size.width - tRadius,
      size.height - tRadius,
      tRadius,
      tRadius,
    );

    final path = Path()
      ..addRect(clippingRect0)
      ..addRect(clippingRect1)
      ..addRect(clippingRect2)
      ..addRect(clippingRect3);

    canvas.clipPath(path);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant QRBorderPainterSmall oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
