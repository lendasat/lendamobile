import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Get gradient colors based on median fee and block status
/// Uses vibrant colors that transition based on fee intensity
List<Color> getGradientColors(
    double medianFee, bool isAccepted, BuildContext? context) {
  double ratio = (medianFee.clamp(0, 400) / 400);

  int r, g, b;
  if (isAccepted) {
    // Blue to red gradient for accepted blocks
    // Low fee = blue, High fee = red
    r = (255 * ratio).round();
    g = 0;
    b = (255 * (1 - ratio)).round();
  } else {
    // Green to red gradient for pending/mempool blocks
    // Low fee = green, High fee = red
    r = (255 * ratio).round();
    g = (255 * (1 - ratio)).round();
    b = 0;
  }

  Color firstColor = Color.fromRGBO(r, g, b, 1);
  // Slightly adjust the second color for gradient effect
  Color secondColor = Color.fromRGBO(
    (r + (isAccepted ? 250 : 250)).clamp(0, 255),
    (g + (isAccepted ? 50 : -50)).clamp(0, 255),
    (b + (isAccepted ? -50 : 50)).clamp(0, 255),
    1,
  );

  return [firstColor, secondColor];
}

/// Get box decoration for block widgets with gradient and shadow
BoxDecoration getDecoration(num medianFee, bool isAccepted,
    {BuildContext? context}) {
  List<Color> gradientColors = getGradientColors(
    medianFee.toDouble(),
    isAccepted,
    context,
  );

  return BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: gradientColors.first.withValues(alpha: 0.5),
        offset: const Offset(-16, -16),
      ),
    ],
    borderRadius: AppTheme.cardRadiusMid,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
    ),
  );
}

/// Helper function to lighten a color
Color lighten(Color color, [int amount = 10]) {
  assert(amount >= 0 && amount <= 100);

  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + (amount / 100)).clamp(0.0, 1.0);

  return hsl.withLightness(lightness).toColor();
}

/// Helper function to darken a color
Color darken(Color color, [int amount = 10]) {
  assert(amount >= 0 && amount <= 100);

  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness - (amount / 100)).clamp(0.0, 1.0);

  return hsl.withLightness(lightness).toColor();
}
