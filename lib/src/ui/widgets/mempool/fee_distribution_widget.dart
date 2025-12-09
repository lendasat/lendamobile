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
              size: AppTheme.cardPadding * 0.75,
            ),
            text: AppLocalizations.of(context)!.feeDistribution,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${_formatAmount(((totalFees / 100000000) * currentUSD).toStringAsFixed(0))}',
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.elementSpacing),

          // Median fee
          Text(
            '${AppLocalizations.of(context)!.medianFee} ~\$${(((medianFee * 140) / 100000000) * currentUSD).toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: AppTheme.white90),
          ),

          const SizedBox(height: AppTheme.elementSpacing),

          // Fee distribution gauge
          SizedBox(
            width: AppTheme.cardPadding * 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SfLinearGauge(
                  showTicks: false,
                  showLabels: false,
                  useRangeColorForAxis: true,
                  axisTrackStyle: const LinearAxisTrackStyle(
                    thickness: AppTheme.cardPadding,
                    color: Colors.grey,
                    edgeStyle: LinearEdgeStyle.bothCurve,
                    gradient: LinearGradient(
                      colors: [AppTheme.errorColor, AppTheme.successColor],
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
                        height: AppTheme.cardPadding * 1.25,
                        width: AppTheme.elementSpacing * 0.75,
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
                  padding: const EdgeInsets.only(top: AppTheme.elementSpacing),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(((feeRange.first * 140) / 100000000) * currentUSD).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppTheme.errorColor,
                            ),
                      ),
                      Text(
                        '\$${(((feeRange.last * 140) / 100000000) * currentUSD).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppTheme.successColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.cardPadding),
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
