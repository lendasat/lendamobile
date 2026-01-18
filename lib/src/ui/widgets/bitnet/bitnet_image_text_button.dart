import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button with an icon/image and text below it
/// Used for action buttons like Send, Receive, Buy, etc.
class BitNetImageWithTextButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final String? image;
  final double? width;
  final double? height;
  final IconData? fallbackIcon;
  final double? fallbackIconSize;

  const BitNetImageWithTextButton(
    this.title,
    this.onTap, {
    super.key,
    this.image,
    this.width,
    this.height,
    this.fallbackIcon,
    this.fallbackIconSize,
  });

  @override
  State<BitNetImageWithTextButton> createState() =>
      _BitNetImageWithTextButtonState();
}

class _BitNetImageWithTextButtonState extends State<BitNetImageWithTextButton>
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

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    // Ensure forward completes before reversing (for quick taps)
    _scaleController.forward().then((_) => _scaleController.reverse());
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final buttonSize = widget.width ?? 60.0;
    final iconSize = widget.fallbackIconSize ?? AppTheme.iconSize * 1.25;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: buttonSize,
              height: widget.height ?? buttonSize,
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(buttonSize / 3),
                border: isLight
                    ? Border.all(
                        color: Colors.black.withValues(alpha: 0.1),
                        width: 1,
                      )
                    : null,
                boxShadow: isLight
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.image != null
                    ? Image.asset(
                        widget.image!,
                        width: iconSize,
                        height: iconSize,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            widget.fallbackIcon ?? Icons.error,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: iconSize,
                          );
                        },
                      )
                    : Icon(
                        widget.fallbackIcon ?? Icons.circle,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: iconSize,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: buttonSize * 1.2,
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
