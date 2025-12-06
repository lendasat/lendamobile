import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// A button with an icon/image and text below it
/// Used for action buttons like Send, Receive, Buy, etc.
class BitNetImageWithTextButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final buttonSize = width ?? 60.0;
    final iconSize = fallbackIconSize ?? BitNetTheme.iconSize * 1.25;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: buttonSize,
            height: height ?? buttonSize,
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
              child: image != null
                  ? Image.asset(
                      image!,
                      width: iconSize,
                      height: iconSize,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          fallbackIcon ?? Icons.error,
                          color: theme.primaryWhite,
                          size: iconSize,
                        );
                      },
                    )
                  : Icon(
                      fallbackIcon ?? Icons.circle,
                      color: theme.primaryWhite,
                      size: iconSize,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: buttonSize * 1.2,
            child: Text(
              title,
              style: TextStyle(
                color: theme.primaryWhite,
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
    );
  }
}
