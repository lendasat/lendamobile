import 'package:flutter/material.dart';

class BottomNavGradient extends StatelessWidget {
  const BottomNavGradient({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight ? Colors.grey.shade200 : Colors.black;

    return Container(
      height: 42, // ~cardPadding * 1.75
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.6, 0.7, 0.9, 1.0],
          colors: [
            baseColor.withValues(alpha: 0.0001),
            baseColor.withValues(alpha: 0.3),
            baseColor.withValues(alpha: 0.6),
            baseColor.withValues(alpha: 0.9),
            baseColor,
            baseColor,
          ],
        ),
      ),
    );
  }
}
