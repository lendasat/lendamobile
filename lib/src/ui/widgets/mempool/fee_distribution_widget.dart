import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

/// Widget displaying block fee distribution
class FeeDistributionWidget extends StatelessWidget {
  final num medianFee;
  final num totalFees;
  final List<num> feeRange;
  final num currentUSD;

  const FeeDistributionWidget({
    super.key,
    required this.medianFee,
    required this.totalFees,
    required this.feeRange,
    required this.currentUSD,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        children: [
          // Header with fee information
          ArkListTile(
            leading: const Icon(
              FontAwesomeIcons.moneyBill,
              size: BitNetTheme.cardPadding * 0.75,
            ),
            text: AppLocalizations.of(context)!.feeDistribution,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${_formatAmount(((totalFees / 100000000) * currentUSD).toStringAsFixed(0))}',
                  style: const TextStyle(
                    color: BitNetTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: BitNetTheme.elementSpacing),

          // Median fee
          Text(
            '${AppLocalizations.of(context)!.medianFee} ~\$${(((medianFee * 140) / 100000000) * currentUSD).toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: BitNetTheme.white90),
          ),

          const SizedBox(height: BitNetTheme.elementSpacing),

          // Fee distribution gauge
          SizedBox(
            width: BitNetTheme.cardPadding * 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SfLinearGauge(
                  showTicks: false,
                  showLabels: false,
                  useRangeColorForAxis: true,
                  axisTrackStyle: const LinearAxisTrackStyle(
                    thickness: BitNetTheme.cardPadding,
                    color: Colors.grey,
                    edgeStyle: LinearEdgeStyle.bothCurve,
                    gradient: LinearGradient(
                      colors: [BitNetTheme.errorColor, BitNetTheme.successColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.1, 0.9],
                      tileMode: TileMode.clamp,
                    ),
                  ),
                  minimum: feeRange.first.toDouble(),
                  maximum: feeRange.last.toDouble(),
                  markerPointers: [
                    LinearWidgetPointer(
                      value: medianFee.toDouble(),
                      child: Container(
                        height: BitNetTheme.cardPadding * 1.25,
                        width: BitNetTheme.elementSpacing * 0.75,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Fee range labels
                Padding(
                  padding: const EdgeInsets.only(top: BitNetTheme.elementSpacing),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(((feeRange.first * 140) / 100000000) * currentUSD).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: BitNetTheme.errorColor,
                            ),
                      ),
                      Text(
                        '\$${(((feeRange.last * 140) / 100000000) * currentUSD).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: BitNetTheme.successColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: BitNetTheme.cardPadding),
        ],
      ),
    );
  }

  // Helper method to format amounts with commas
  String _formatAmount(String price) {
    String priceInText = "";
    int counter = 0;
    for (int i = (price.length - 1); i >= 0; i--) {
      counter++;
      String str = price[i];
      if ((counter % 3) != 0 && i != 0) {
        priceInText = "$str$priceInText";
      } else if (i == 0) {
        priceInText = "$str$priceInText";
      } else {
        priceInText = ",$str$priceInText";
      }
    }
    return priceInText.trim();
  }
}
