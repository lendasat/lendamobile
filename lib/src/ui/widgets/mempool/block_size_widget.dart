import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';

/// Widget displaying block size information
class BlockSizeWidget extends StatelessWidget {
  final double sizeInBytes;
  final double weightInBytes;
  final bool isAccepted;

  const BlockSizeWidget({
    super.key,
    required this.sizeInBytes,
    required this.weightInBytes,
    this.isAccepted = true,
  });

  @override
  Widget build(BuildContext context) {
    // Convert to MB
    double mbSize = sizeInBytes / 1000000;
    double mwu = weightInBytes / 1000000;

    // Calculate the width based on the ratio
    double maxWidth = AppTheme.cardPadding * 3;
    double ratio = (mbSize / mwu) * maxWidth;
    double orangeContainerWidth = ratio.clamp(0, maxWidth);

    return GlassContainer(
      height: isAccepted ? null : AppTheme.cardPadding * 6.5,
      width: isAccepted ? null : AppTheme.cardPadding * 6.5,
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
                AppLocalizations.of(context)!.blockSize,
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

          const SizedBox(height: AppTheme.cardPadding * 0.5),

          // Size visualization
          Stack(
            children: [
              // Background container
              Container(
                height: AppTheme.cardPadding * 3,
                width: AppTheme.cardPadding * 3,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.cardRadiusSmall,
                  color: Colors.grey,
                ),
              ),

              // Filled container representing the ratio
              Container(
                height: AppTheme.cardPadding * 3,
                width: orangeContainerWidth,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.cardRadiusSmall,
                  color: AppTheme.colorBitcoin,
                ),
              ),

              // Text overlay showing the size
              SizedBox(
                height: AppTheme.cardPadding * 3,
                width: AppTheme.cardPadding * 3,
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${mbSize.toStringAsFixed(2)} MB',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: AppTheme.white90,
                          shadows: [AppTheme.boxShadowBig],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.elementSpacing * 0.75),

          // Size reference
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "of ${mwu.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Transform.translate(
                offset: const Offset(0, 2),
                child: Text(
                  isAccepted ? ' MB  ' : ' MWU  ',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
