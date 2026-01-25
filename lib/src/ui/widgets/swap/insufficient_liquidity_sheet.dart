import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.cardPadding),
            // Warning icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 36,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding * 1.5),
            // Title
            Text(
              'Service Temporarily Unavailable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Description
            Text(
              'The LendaSwap service currently doesn\'t have sufficient funds to facilitate this swap.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              'Please try again in a couple of hours when liquidity has been replenished.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding * 1.5),
            // Suggestions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You can also try:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white80 : AppTheme.black80,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestion(
                    context,
                    isDark,
                    'A smaller swap amount',
                  ),
                  const SizedBox(height: 4),
                  _buildSuggestion(
                    context,
                    isDark,
                    'Swapping to a different token (e.g., USDC on Polygon)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding * 1.5),
            // Dismiss button
            LongButtonWidget(
              title: 'Got it',
              buttonType: ButtonType.solid,
              customWidth: double.infinity,
              onTap: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, bool isDark, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u2022 ',
          style: TextStyle(
            color: isDark ? AppTheme.white60 : AppTheme.black60,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
        ),
      ],
    );
  }
}
