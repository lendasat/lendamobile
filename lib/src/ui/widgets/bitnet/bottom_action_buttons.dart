import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/bottom_nav_gradient.dart';
import 'package:flutter/material.dart';

/// Container for floating action buttons at the bottom of a screen.
///
/// Provides consistent styling with:
/// - Gradient fade at top (like bitnetgithub)
/// - Background color matching theme
/// - SafeArea padding
/// - Proper padding
///
/// Use this to wrap any bottom action content (buttons, text, etc.)
class BottomActionContainer extends StatelessWidget {
  final Widget child;

  /// Whether to show the top gradient. Defaults to true.
  final bool showGradient;

  const BottomActionContainer({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? Colors.grey.shade200 : Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGradient) const BottomNavGradient(),
        Container(
          color: backgroundColor,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.cardPadding,
                right: AppTheme.cardPadding,
                bottom: AppTheme.elementSpacing,
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single centered button at the bottom of a screen.
///
/// Convenience widget that combines [BottomActionContainer] with a [LongButtonWidget].
///
/// For multiple buttons or more complex layouts, use [BottomActionContainer] directly.
class BottomCenterButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final ButtonState state;
  final ButtonType buttonType;
  final bool isLoading;
  final LinearGradient? buttonGradient;

  /// Optional widget to show below the button (e.g., error text, info text)
  final Widget? bottomWidget;

  const BottomCenterButton({
    super.key,
    required this.title,
    required this.onTap,
    this.state = ButtonState.idle,
    this.buttonType = ButtonType.primary,
    this.isLoading = false,
    this.buttonGradient,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return BottomActionContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LongButtonWidget(
            title: title,
            customWidth: double.infinity,
            state: state,
            buttonType: buttonType,
            isLoading: isLoading,
            buttonGradient: buttonGradient,
            onTap: onTap,
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: AppTheme.elementSpacing),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}

/// Two buttons side by side at the bottom of a screen.
///
/// Left button is typically secondary (cancel, back).
/// Right button is typically primary (confirm, submit).
class BottomButtonPair extends StatelessWidget {
  final String leftTitle;
  final String rightTitle;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;
  final ButtonType leftButtonType;
  final ButtonType rightButtonType;
  final LinearGradient? rightButtonGradient;
  final bool isRightLoading;

  const BottomButtonPair({
    super.key,
    required this.leftTitle,
    required this.rightTitle,
    this.onLeftTap,
    this.onRightTap,
    this.leftButtonType = ButtonType.secondary,
    this.rightButtonType = ButtonType.primary,
    this.rightButtonGradient,
    this.isRightLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomActionContainer(
      child: Row(
        children: [
          Expanded(
            child: LongButtonWidget(
              title: leftTitle,
              buttonType: leftButtonType,
              customWidth: double.infinity,
              onTap: onLeftTap,
            ),
          ),
          const SizedBox(width: AppTheme.elementSpacing),
          Expanded(
            child: LongButtonWidget(
              title: rightTitle,
              buttonType: rightButtonType,
              customWidth: double.infinity,
              buttonGradient: rightButtonGradient,
              isLoading: isRightLoading,
              onTap: onRightTap,
            ),
          ),
        ],
      ),
    );
  }
}
