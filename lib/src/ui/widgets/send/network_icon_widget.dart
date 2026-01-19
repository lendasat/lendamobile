import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget to display network icons (Bitcoin, Lightning, Arkade)
class NetworkIconWidget extends StatelessWidget {
  final String networkName;
  final double size;
  final Color? color;

  const NetworkIconWidget({
    super.key,
    required this.networkName,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).hintColor;

    switch (networkName.toLowerCase()) {
      case 'lightning':
        return Icon(
          Icons.bolt_rounded,
          size: size,
          color: iconColor,
        );
      case 'onchain':
      case 'bitcoin':
        return Icon(
          FontAwesomeIcons.bitcoin,
          size: size * 0.85,
          color: iconColor,
        );
      case 'arkade':
      case 'ark':
        return SvgPicture.asset(
          'assets/images/icon/ark_logo.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      default:
        return Icon(
          Icons.help_outline,
          size: size,
          color: iconColor,
        );
    }
  }
}
