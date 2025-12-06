import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/colorhelper.dart'
    as colorhelper;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Card displaying current Bitcoin transaction fees
class TransactionFeeCard extends StatelessWidget {
  final RecommendedFees? fees;
  final num currentUSD;
  final bool isLoading;

  const TransactionFeeCard({
    super.key,
    required this.fees,
    required this.currentUSD,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BitNetTheme.colorBitcoin),
      );
    }

    if (fees == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(BitNetTheme.cardPadding),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.coins,
                    size: BitNetTheme.cardPadding * 0.75,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const SizedBox(width: BitNetTheme.elementSpacing),
                  Text(
                    AppLocalizations.of(context)!.transactionFees,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: BitNetTheme.cardPadding),

              // Fee amounts
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeeColumn(
                    context: context,
                    title: AppLocalizations.of(context)!.low,
                    feeAmount:
                        '\$ ${_dollarConversion(fees!.hourFee).toStringAsFixed(2)}',
                    feeColor: colorhelper.lighten(
                      colorhelper
                          .getGradientColors(
                            fees!.hourFee,
                            false,
                            context,
                          )
                          .first,
                      25,
                    ),
                    icon: Icons.speed,
                    iconColor: BitNetTheme.errorColor.withValues(alpha: 0.7),
                  ),
                  _buildFeeColumn(
                    context: context,
                    title: AppLocalizations.of(context)!.halfHour,
                    feeAmount:
                        '\$ ${_dollarConversion(fees!.halfHourFee).toStringAsFixed(2)}',
                    feeColor: colorhelper.lighten(
                      colorhelper
                          .getGradientColors(
                            fees!.halfHourFee,
                            false,
                            context,
                          )
                          .first,
                      25,
                    ),
                    icon: Icons.speed,
                    iconColor: BitNetTheme.colorBitcoin.withValues(alpha: 0.8),
                  ),
                  _buildFeeColumn(
                    context: context,
                    title: AppLocalizations.of(context)!.fastest10Min,
                    feeAmount:
                        '\$ ${_dollarConversion(fees!.fastestFee).toStringAsFixed(2)}',
                    feeColor: colorhelper.lighten(
                      colorhelper
                          .getGradientColors(
                            fees!.fastestFee,
                            false,
                            context,
                          )
                          .first,
                      25,
                    ),
                    icon: Icons.speed,
                    iconColor: BitNetTheme.successColor,
                  ),
                ],
              ),

              const SizedBox(height: BitNetTheme.elementSpacing),
              const SizedBox(height: BitNetTheme.elementSpacing),

              // Confirmation time
              Text(
                "Estimated confirmation time",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BitNetTheme.white60
                          : BitNetTheme.black60,
                    ),
              ),
              const SizedBox(height: BitNetTheme.elementSpacing),

              // Time estimates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeEstimate(
                    context,
                    "~60 min",
                    BitNetTheme.errorColor.withValues(alpha: 0.7),
                  ),
                  _buildTimeEstimate(
                    context,
                    "~30 min",
                    BitNetTheme.colorBitcoin.withValues(alpha: 0.8),
                  ),
                  _buildTimeEstimate(
                    context,
                    "Next block",
                    BitNetTheme.successColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to convert fee to dollar amount
  double _dollarConversion(num fee) {
    return currentUSD * ((fee * (560 / 4) / 100000000));
  }

  // Widget to display fee column with icon, title, and amount
  Widget _buildFeeColumn({
    required BuildContext context,
    required String title,
    required String feeAmount,
    required Color feeColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withValues(alpha: 0.15),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 28)),
        ),
        const SizedBox(height: BitNetTheme.elementSpacing),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: BitNetTheme.elementSpacing / 2),
        Text(
          feeAmount,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: feeColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // Widget to display time estimate pill
  Widget _buildTimeEstimate(BuildContext context, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BitNetTheme.elementSpacing,
        vertical: BitNetTheme.elementSpacing / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BitNetTheme.cardRadiusSmall,
      ),
      child: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
