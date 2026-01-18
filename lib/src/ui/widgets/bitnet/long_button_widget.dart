import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/solid_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A long/wide button widget with customizable styling
/// Ported directly from BitNet project - maintains exact same behavior
class LongButtonWidget extends StatefulWidget {
  final String title;
  final double customWidth;
  final double customHeight;
  final TextStyle? titleStyle;
  final ButtonState state;
  final Widget? leadingIcon;
  final Function()? onTap;
  final Gradient? buttonGradient;
  final dynamic textColor;
  final ButtonType buttonType;
  final bool backgroundPainter;
  final List<BoxShadow>? customShadow;
  final Function()? onTapDisabled;
  // Additional parameters for compatibility
  final bool isLoading;
  final bool enabled;
  final Widget? trailingIcon;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const LongButtonWidget({
    super.key,
    required this.title,
    this.onTap,
    this.titleStyle,
    this.buttonGradient,
    this.textColor,
    this.state = ButtonState.idle,
    this.leadingIcon,
    this.customWidth = AppTheme.cardPadding * 12,
    this.customHeight = AppTheme.cardPadding * 2.125,
    this.buttonType = ButtonType.solid,
    this.backgroundPainter = true,
    this.customShadow,
    this.onTapDisabled,
    // Compatibility parameters
    this.isLoading = false,
    this.enabled = true,
    this.trailingIcon,
    this.backgroundColor,
    this.padding,
    this.textStyle,
  });

  @override
  State<LongButtonWidget> createState() => _LongButtonWidgetState();
}

class _LongButtonWidgetState extends State<LongButtonWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool _animating = false;

  void _triggerAnimation() {
    if (!_animating) {
      _animating = true;
      _scaleController.forward().then((_) {
        _scaleController.reverse().then((_) {
          _animating = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine effective state
    ButtonState effectiveState = widget.state;
    if (widget.isLoading) {
      effectiveState = ButtonState.loading;
    } else if (!widget.enabled) {
      effectiveState = ButtonState.disabled;
    }

    // Slightly rounded corners (20px)
    final borderRadius = BorderRadius.circular(20.0);
    const borderRadiusNum = 20.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Stack(
        children: [
          // Background content
          Container(
            decoration: BoxDecoration(
              boxShadow: widget.customShadow ??
                  [
                    if (widget.buttonType == ButtonType.solid ||
                        widget.buttonType == ButtonType.primary)
                      BoxShadow(
                        color: AppTheme.colorBitcoin.withValues(alpha: 0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 15,
                        spreadRadius: -2,
                      )
                    else
                      AppTheme.boxShadowProfile,
                  ],
              borderRadius: borderRadius,
            ),
            child: widget.buttonType == ButtonType.solid ||
                    widget.buttonType == ButtonType.primary
                ? SolidContainer(
                    gradientColors: effectiveState == ButtonState.disabled
                        ? [Colors.grey, Colors.grey]
                        : _isHovered
                            ? [
                                darken(
                                    theme.colorScheme.secondaryContainer, 10),
                                darken(theme.colorScheme.tertiaryContainer, 10),
                              ]
                            : theme.colorScheme.primary == AppTheme.colorBitcoin
                                ? [
                                    AppTheme.colorBitcoin,
                                    AppTheme.colorBitcoin,
                                  ]
                                : [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                    gradientBegin: Alignment.topLeft,
                    gradientEnd: Alignment.bottomRight,
                    borderRadius: borderRadiusNum,
                    width: widget.customWidth,
                    height: widget.customHeight,
                    normalPainter: widget.backgroundPainter,
                    borderWidth: widget.backgroundPainter ? 1.5 : 1,
                    child: Container(),
                  )
                : GlassContainer(
                    height: widget.customHeight,
                    width: widget.customWidth,
                    border: (effectiveState == ButtonState.disabled ? 0 : 0) ==
                            0
                        ? null
                        : Border.all(
                            width:
                                effectiveState == ButtonState.disabled ? 0 : 0,
                            color: Theme.of(context).dividerColor,
                          ),
                    opacity: 0.1,
                    borderRadius: borderRadius,
                    child: Container(),
                  ),
          ),
          // The InkWell goes on top of the background
          SizedBox(
            width: widget.customWidth,
            height: widget.customHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                hoverColor: Colors.black.withValues(alpha: 0.1),
                onHover: (value) => setState(() => _isHovered = value),
                onTap: effectiveState == ButtonState.disabled
                    ? widget.onTapDisabled
                    : () {
                        _triggerAnimation();
                        HapticFeedback.lightImpact();
                        widget.onTap?.call();
                      },
                borderRadius: borderRadius,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                  ),
                  child: effectiveState == ButtonState.loading
                      ? dotProgress(
                          context,
                          size: 14,
                          color: widget.textColor ??
                              (widget.buttonType == ButtonType.solid ||
                                      widget.buttonType == ButtonType.primary
                                  ? const Color(0xFF1A0A00)
                                  : theme.brightness == Brightness.light
                                      ? AppTheme.black70
                                      : AppTheme.white90),
                        )
                      : Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.leadingIcon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: widget.leadingIcon,
                                  ),
                                Flexible(
                                  child: Text(
                                    widget.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: widget.titleStyle ??
                                        widget.textStyle ??
                                        TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: widget.textColor ??
                                              (widget.buttonType ==
                                                          ButtonType.solid ||
                                                      widget.buttonType ==
                                                          ButtonType.primary
                                                  ? const Color(0xFF1A0A00)
                                                  : theme.brightness ==
                                                          Brightness.light
                                                      ? AppTheme.black70
                                                      : AppTheme.white90),
                                        ),
                                  ),
                                ),
                                if (widget.trailingIcon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: widget.trailingIcon,
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
