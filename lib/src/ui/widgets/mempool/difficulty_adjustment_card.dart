import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';

/// Card displaying Bitcoin network difficulty adjustment information
class DifficultyAdjustmentCard extends StatelessWidget {
  final DifficultyAdjustment? da;
  final String? days;
  final bool isLoading;

  const DifficultyAdjustmentCard({
    Key? key,
    required this.da,
    required this.days,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return dotProgress(context);
    }

    if (da == null) {
      return const SizedBox();
    }

    final loc = Provider.of<TimezoneService>(
      context,
      listen: false,
    ).location;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                  SizedBox(width: AppTheme.elementSpacing),
                  Text(
                    "Bitcoin Network Difficulty",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              SizedBox(height: AppTheme.cardPadding),

              // Content
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Date information
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        "Next adjustment in:",
                        "~$days",
                        Icons.calendar_today,
                      ),
                      SizedBox(height: AppTheme.elementSpacing * 1.5),
                      _buildInfoRow(
                        context,
                        "Estimated date:",
                        DateFormat.yMMMd().format(
                          DateTime.fromMillisecondsSinceEpoch(
                            da!.estimatedRetargetDate!.toInt(),
                          ).toUtc().add(
                                Duration(
                                    milliseconds: loc.currentTimeZone.offset),
                              ),
                        ),
                        Icons.event,
                      ),
                      SizedBox(height: AppTheme.elementSpacing * 1.5),
                      _buildInfoRow(
                        context,
                        "Estimated time:",
                        DateFormat.jm().format(
                          DateTime.fromMillisecondsSinceEpoch(
                            da!.estimatedRetargetDate!.toInt(),
                          ).toUtc().add(
                                Duration(
                                    milliseconds: loc.currentTimeZone.offset),
                              ),
                        ),
                        Icons.access_time,
                      ),
                    ],
                  ),

                  // Right side - Difficulty change visualization
                  _buildDifficultyChangeIndicator(context),
                ],
              ),

              SizedBox(height: AppTheme.elementSpacing),
              SizedBox(height: AppTheme.elementSpacing),

              // Footer
              Text(
                "Difficulty adjusts every 2016 blocks (~2 weeks)",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.white60
                          : AppTheme.black60,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the difficulty change indicator
  Widget _buildDifficultyChangeIndicator(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: da!.difficultyChange!.isNegative
              ? AppTheme.errorColor.withValues(alpha: 0.5)
              : AppTheme.successColor.withValues(alpha: 0.5),
          width: 3,
        ),
        color: da!.difficultyChange!.isNegative
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : AppTheme.successColor.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            da!.difficultyChange!.isNegative
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: da!.difficultyChange!.isNegative
                ? AppTheme.errorColor
                : AppTheme.successColor,
            size: 36,
          ),
          SizedBox(height: 8),
          Text(
            da!.difficultyChange!.isNegative
                ? '${da!.difficultyChange!.abs().toStringAsFixed(2)}%'
                : '${da!.difficultyChange!.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: da!.difficultyChange!.isNegative
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 4),
          Text(
            da!.difficultyChange!.isNegative ? "Decrease" : "Increase",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: da!.difficultyChange!.isNegative
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.white60),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.white60
                        : AppTheme.black60,
                  ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
