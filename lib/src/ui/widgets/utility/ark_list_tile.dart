import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/gradient_border.dart';
import 'package:flutter/material.dart';

class ArkListTile extends StatelessWidget {
  final Widget? leading;
  final String text;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry margin;
  final Function()? onTap;
  final Function()? onLongPress;
  final Color? tileColor;
  final ShapeBorder? shape;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? customTitle;
  final bool selected;
  final bool isActive;

  const ArkListTile({
    super.key,
    this.leading,
    this.text = "",
    this.subtitle,
    this.trailing,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    this.onTap,
    this.onLongPress,
    this.tileColor,
    this.shape,
    this.titleStyle,
    this.subtitleStyle,
    this.customTitle,
    this.selected = false,
    this.isActive = false,
    this.margin = const EdgeInsets.only(
      top: 8,
      left: 4,
      right: 4,
    ),
  });

  @override
  Widget build(BuildContext context) {
    
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      clipBehavior: Clip.hardEdge,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: selected
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
            : isActive
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
        border: selected
            ? GradientBoxBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                isLightTheme: isLight,
              )
            : GradientBoxBorder(
                isTransparent: true,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                isLightTheme: isLight,
              ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: shape,
        child: Padding(
          padding: contentPadding,
          child: Row(
            children: <Widget>[
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (customTitle != null) customTitle!,
                    if (customTitle == null)
                      Text(
                        text,
                        style: titleStyle ??
                            TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: subtitleStyle ??
                            TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
