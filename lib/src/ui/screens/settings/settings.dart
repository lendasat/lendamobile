import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings_view.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings_style_view.dart';
import 'package:ark_flutter/src/ui/screens/settings/change_language.dart';
import 'package:ark_flutter/src/ui/screens/settings/change_timezone.dart';
import 'package:ark_flutter/src/ui/screens/settings/change_currency.dart';
import 'package:ark_flutter/src/ui/screens/settings/recovery_key_view.dart';
import 'package:ark_flutter/src/ui/screens/settings/feedback_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/emergency_recovery_view.dart';
import 'package:ark_flutter/src/ui/screens/settings/preferences_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/claim_sats_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/chart_time_range_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/agbs_and_impressum_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  final String aspId;

  const Settings({
    super.key,
    required this.aspId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    // Wrap with Consumer to rebuild when theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopScope(
          canPop: controller.currentTab == 'main',
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && controller.currentTab != 'main') {
              controller.resetToMain();
            }
          },
          child: _buildCurrentTab(context, controller),
        );
      },
    );
  }

  Widget _buildCurrentTab(BuildContext context, SettingsController controller) {
    switch (controller.currentTab) {
      case 'style':
        return const SettingsStyleView();
      case 'language':
        return const ChangeLanguage();
      case 'timezone':
        return const ChangeTimezone();
      case 'currency':
        return const ChangeCurrency();
      case 'recovery':
        return RecoveryKeyView(key: const ValueKey('recovery_key_view'));
      case 'feedback':
        return const FeedbackScreen();
      case 'emergency_recovery':
        return const EmergencyRecoveryView();
      case 'preferences':
        return const PreferencesScreen();
      case 'claim_sats':
        return const ClaimSatsScreen();
      case 'chart_time_range':
        return const ChartTimeRangeScreen();
      case 'agbs':
        return const AgbsAndImpressumScreen();
      case 'main':
      default:
        return SettingsView(aspId: aspId);
    }
  }
}
