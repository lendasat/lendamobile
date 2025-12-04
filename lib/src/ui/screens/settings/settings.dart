import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings_main_view.dart';
import 'package:ark_flutter/src/ui/screens/change_style_screen.dart';
import 'package:ark_flutter/src/ui/screens/change_language_screen.dart';
import 'package:ark_flutter/src/ui/screens/change_timezone_screen.dart';
import 'package:ark_flutter/src/ui/screens/change_currency_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  final String aspId;

  const Settings({
    Key? key,
    required this.aspId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    // Wrap with Consumer to rebuild when theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopScope(
          canPop: controller.currentTab == 'main',
          onPopInvoked: (didPop) {
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
        return const ChangeStyleScreen();
      case 'language':
        return const ChangeLanguageScreen();
      case 'timezone':
        return const ChangeTimezoneScreen();
      case 'currency':
        return const ChangeCurrencyScreen();
      case 'main':
      default:
        return SettingsMainView(aspId: aspId);
    }
  }
}
