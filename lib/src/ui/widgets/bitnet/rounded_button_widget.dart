import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A rounded/circular button widget with icon
class RoundedButtonWidget extends StatefulWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;
  final ButtonType buttonType;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isLoading;
  final bool enabled;
  final double hitSlop;

  const RoundedButtonWidget({
    super.key,
    required this.iconData,
    this.onTap,
    this.size = 44,
    this.iconSize,
    this.buttonType = ButtonType.solid,
    this.iconColor,
    this.backgroundColor,
    this.isLoading = false,
    this.enabled = true,
    this.hitSlop = 0,
  });

  @override
  State<RoundedButtonWidget> createState() => _RoundedButtonWidgetState();
}

class _RoundedButtonWidgetState extends State<RoundedButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  void _handleTap() {
    if (widget.enabled && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Determine colors based on button type
    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.buttonType) {
      case ButtonType.solid:
        bgColor = widget.backgroundColor ?? AppTheme.colorBitcoin;
        fgColor = widget.iconColor ?? Colors.white;
        border = null;
        break;
      case ButtonType.transparent:
        bgColor = isLight
            ? Colors.black.withValues(alpha: 0.04)
            : const Color(0xFF2A2A2A);
        fgColor = widget.iconColor ?? Theme.of(context).colorScheme.onSurface;
        border = isLight
            ? Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1)
            : null;
        break;
      case ButtonType.outlined:
        bgColor = Colors.transparent;
        fgColor = widget.iconColor ?? Theme.of(context).colorScheme.onSurface;
        border = Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.5,
        );
        break;
      case ButtonType.primary:
        bgColor = widget.backgroundColor ?? AppTheme.colorBitcoin;
        fgColor = widget.iconColor ?? Colors.white;
        border = null;
        break;
      case ButtonType.secondary:
        bgColor =
            widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
        fgColor = widget.iconColor ?? Theme.of(context).colorScheme.onSurface;
        border = null;
        break;
      case ButtonType.disabled:
        bgColor = Theme.of(context).colorScheme.secondary;
        fgColor = Theme.of(context).hintColor;
        border = null;
        break;
    }

    if (!widget.enabled) {
      bgColor = Theme.of(context).colorScheme.secondary;
      fgColor = Theme.of(context).hintColor;
    }

    final button = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.size / 3),
        border: border,
      ),
      child: widget.isLoading
          ? dotProgress(context, size: 14, color: fgColor)
          : Center(
              child: Icon(
                widget.iconData,
                color: fgColor,
                size: widget.iconSize ?? widget.size * 0.5,
              ),
            ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.hitSlop > 0
            ? Padding(
                padding: EdgeInsets.all(widget.hitSlop),
                child: button,
              )
            : button,
      ),
    );
  }
}
