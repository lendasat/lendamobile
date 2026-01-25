import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bottom_action_buttons.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';

/// Bottom sheet shown when LendaSwap service has insufficient liquidity.
class InsufficientLiquiditySheet extends StatelessWidget {
  final VoidCallback? onDismiss;

  const InsufficientLiquiditySheet({
    super.key,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppTheme.cardPadding),
              // Bani sad/shocked image
              SizedBox(
                height: 120,
                child: Image.asset(
                  'assets/images/bani/bani_shocked.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppTheme.cardPadding),
              // Title
              Text(
                'We\'re Out of Liquidity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              // Description
              Text(
                'We don\'t have enough funds for this swap right now. Please try again later or use a different token.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.cardPadding),
            ],
          ),
        ),
        // Bottom button
        BottomCenterButton(
          title: 'Got it',
          buttonType: ButtonType.solid,
          transparentBackground: true,
          onTap: () {
            Navigator.pop(context);
            onDismiss?.call();
          },
        ),
      ],
    );
  }
}
