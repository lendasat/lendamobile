import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget displaying block health information
class BlockHealthWidget extends StatelessWidget {
  final double matchRate;
  final bool isAccepted;

  const BlockHealthWidget({
    super.key,
    required this.matchRate,
    this.isAccepted = true,
  });

  @override
  Widget build(BuildContext context) {
    // For unaccepted blocks, assume 100% health since they haven't been mined yet
    final displayRate = isAccepted ? matchRate : 100.0;

    return GlassContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title row with help icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.health,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: AppTheme.elementSpacing / 2),
              Icon(
                Icons.help_outline_rounded,
                color: AppTheme.white80,
                size: AppTheme.cardPadding * 0.75,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.cardPadding * 0.75),

          // Health status icon
          Icon(
            FontAwesomeIcons.faceSmile,
            color: displayRate >= 99
                ? AppTheme.successColor
                : displayRate >= 75 && displayRate < 99
                    ? AppTheme.colorBitcoin
                    : AppTheme.errorColor,
            size: AppTheme.cardPadding * 2.5,
          ),

          const SizedBox(height: AppTheme.elementSpacing * 1.25),

          // Health percentage text
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$displayRate %',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
