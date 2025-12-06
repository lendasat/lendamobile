import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Profile picture type for avatar styling
enum ProfilePictureType {
  /// Default circle avatar
  circle,

  /// Lightning-styled avatar
  lightning,

  /// Square avatar
  square,
}

/// Avatar widget for displaying profile pictures
class Avatar extends StatelessWidget {
  final VoidCallback? onTap;
  final double? size;
  final Uri? mxContent;
  final String? imageUrl;
  final ProfilePictureType type;
  final bool isNft;
  final Color? backgroundColor;
  final IconData? fallbackIcon;

  const Avatar({
    super.key,
    this.onTap,
    this.size,
    this.mxContent,
    this.imageUrl,
    this.type = ProfilePictureType.circle,
    this.isNft = false,
    this.backgroundColor,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final avatarSize = size ?? BitNetTheme.cardPadding * 1.5;
    final borderRadius = type == ProfilePictureType.square
        ? BorderRadius.circular(avatarSize / 4)
        : BorderRadius.circular(avatarSize / 3);

    final String? url = mxContent?.toString() ?? imageUrl;

    Widget avatarContent;
    if (url != null && url.isNotEmpty) {
      avatarContent = ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          url,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(context, theme, avatarSize, isLight);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallbackAvatar(context, theme, avatarSize, isLight);
          },
        ),
      );
    } else {
      avatarContent = _buildFallbackAvatar(context, theme, avatarSize, isLight);
    }

    // Add NFT border if applicable
    if (isNft) {
      avatarContent = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: const LinearGradient(
            colors: [
              BitNetTheme.colorBitcoin,
              BitNetTheme.colorPrimaryGradient,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: avatarContent,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: avatarContent,
    );
  }

  Widget _buildFallbackAvatar(
    BuildContext context,
    AppTheme theme,
    double size,
    bool isLight,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isLight
                ? Colors.black.withValues(alpha: 0.04)
                : theme.tertiaryBlack.withValues(alpha: 0.5)),
        borderRadius: type == ProfilePictureType.square
            ? BorderRadius.circular(size / 4)
            : BorderRadius.circular(size / 3),
        border: isLight
            ? Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              )
            : null,
      ),
      child: Icon(
        fallbackIcon ?? Icons.person,
        color: theme.primaryWhite,
        size: size * 0.6,
      ),
    );
  }
}
