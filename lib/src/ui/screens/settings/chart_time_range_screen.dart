import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChartTimeRangeScreen extends StatelessWidget {
  const ChartTimeRangeScreen({super.key});

  String _getTimeRangeLabel(ChartTimeRange range) {
    switch (range) {
      case ChartTimeRange.day:
        return '1 Day';
      case ChartTimeRange.week:
        return '1 Week';
      case ChartTimeRange.month:
        return '1 Month';
      case ChartTimeRange.year:
        return '1 Year';
      case ChartTimeRange.max:
        return 'All Time';
    }
  }

  IconData _getTimeRangeIcon(ChartTimeRange range) {
    switch (range) {
      case ChartTimeRange.day:
        return Icons.today;
      case ChartTimeRange.week:
        return Icons.date_range;
      case ChartTimeRange.month:
        return Icons.calendar_month;
      case ChartTimeRange.year:
        return Icons.calendar_today;
      case ChartTimeRange.max:
        return Icons.all_inclusive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffoldUnsafe(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        text: 'Chart Time Range',
        context: context,
        onTap: () => controller.resetToMain(),
      ),
      body: Consumer<UserPreferencesService>(
        builder: (context, userPrefs, _) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.elementSpacing * 0.25,
            ),
            child: ListView(
              children: ChartTimeRange.values.map((range) {
                final isSelected = userPrefs.chartTimeRange == range;
                final label = _getTimeRangeLabel(range);
                final icon = _getTimeRangeIcon(range);

                return ArkListTile(
                  leading: RoundedButtonWidget(
                    iconData: icon,
                    onTap: () => userPrefs.setChartTimeRange(range),
                    size: AppTheme.iconSize * 1.5,
                    buttonType: ButtonType.transparent,
                  ),
                  text: label,
                  titleStyle: TextStyle(
                    color: isSelected
                        ? Colors.orange
                        : (isDark ? AppTheme.white90 : AppTheme.black90),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                  onTap: () => userPrefs.setChartTimeRange(range),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
