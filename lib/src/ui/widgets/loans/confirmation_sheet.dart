import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';

/// Generic confirmation bottom sheet for simple yes/no actions.
/// Used for cancel contract, claim collateral, and other confirmation dialogs.
class ConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback onConfirm;

  const ConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Message
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding * 1.5),
          // Buttons
          Row(
            children: [
              Expanded(
                child: LongButtonWidget(
                  title: cancelText,
                  buttonType: ButtonType.secondary,
                  customWidth: double.infinity,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppTheme.elementSpacing),
              Expanded(
                child: LongButtonWidget(
                  title: confirmText,
                  buttonType: ButtonType.primary,
                  customWidth: double.infinity,
                  buttonGradient: confirmColor != null
                      ? LinearGradient(colors: [confirmColor!, confirmColor!])
                      : null,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
        ],
      ),
    );
  }
}
