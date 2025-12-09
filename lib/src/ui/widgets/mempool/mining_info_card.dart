import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// Card displaying mining information for a block
class MiningInfoCard extends StatelessWidget {
  final DateTime timestamp;
  final String poolName;
  final double rewardAmount;

  const MiningInfoCard({
    super.key,
    required this.timestamp,
    required this.poolName,
    required this.rewardAmount,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.elementSpacing * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miner Information text heading
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.truckPickup,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Text(
                    "Miner Information",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Header with timestamp and pool
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timestamp
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFFA1A1AA), // zinc-400
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                // Pool badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin,
                    borderRadius: AppTheme.cardRadiusSmall,
                  ),
                  child: Text(
                    poolName,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: _darken(AppTheme.colorBitcoin, 95),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding * 0.75),

            // Status indicator
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Mined', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding * 0.75),

            // Reward amount
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.bitcoin,
                  color: AppTheme.colorBitcoin,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Miner Reward (Subsidy + fees)',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '\$${NumberFormat('#,##0').format(rewardAmount)}',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: AppTheme.successColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to darken a color
  Color _darken(Color color, [int amount = 10]) {
    assert(amount >= 0 && amount <= 100);

    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - (amount / 100)).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }
}
