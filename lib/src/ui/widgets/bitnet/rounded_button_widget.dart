import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';

/// A rounded/circular button widget with icon
class RoundedButtonWidget extends StatelessWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;
  final ButtonType buttonType;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isLoading;
  final bool enabled;

  const RoundedButtonWidget({
    super.key,
    required this.iconData,
    this.onTap,
    this.size = 40,
    this.iconSize,
    this.buttonType = ButtonType.solid,
    this.iconColor,
    this.backgroundColor,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Determine colors based on button type
    Color bgColor;
    Color fgColor;
    Border? border;

    switch (buttonType) {
      case ButtonType.solid:
        bgColor = backgroundColor ?? AppTheme.colorBitcoin;
        fgColor = iconColor ?? Colors.white;
        border = null;
        break;
      case ButtonType.transparent:
        bgColor = isLight
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.1);
        fgColor = iconColor ?? Theme.of(context).colorScheme.onSurface;
        border = isLight
            ? Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1)
            : null;
        break;
      case ButtonType.outlined:
        bgColor = Colors.transparent;
        fgColor = iconColor ?? Theme.of(context).colorScheme.onSurface;
        border = Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.5,
        );
        break;
      case ButtonType.primary:
        bgColor = backgroundColor ?? AppTheme.colorBitcoin;
        fgColor = iconColor ?? Colors.white;
        border = null;
        break;
      case ButtonType.secondary:
        bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
        fgColor = iconColor ?? Theme.of(context).colorScheme.onSurface;
        border = null;
        break;
      case ButtonType.disabled:
        bgColor = Theme.of(context).colorScheme.secondary;
        fgColor = Theme.of(context).hintColor;
        border = null;
        break;
    }

    if (!enabled) {
      bgColor = Theme.of(context).colorScheme.secondary;
      fgColor = Theme.of(context).hintColor;
    }

    return GestureDetector(
      onTap: enabled && !isLoading ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size / 3),
          border: border,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: size * 0.5,
                  height: size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  iconData,
                  color: fgColor,
                  size: iconSize ?? size * 0.5,
                ),
              ),
      ),
    );
  }
}
