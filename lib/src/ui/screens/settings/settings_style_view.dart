import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/models/app_theme_model.dart';
import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsStyleView extends StatefulWidget {
  const SettingsStyleView({super.key});

  @override
  State<SettingsStyleView> createState() => _SettingsStyleViewState();
}

class _SettingsStyleViewState extends State<SettingsStyleView> {
  ThemeMode _selectedThemeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    // Set initial theme mode based on current theme type
    switch (themeProvider.currentThemeType) {
      case ThemeType.light:
        _selectedThemeMode = ThemeMode.light;
        break;
      case ThemeType.dark:
      case ThemeType.custom:
        _selectedThemeMode = ThemeMode.dark;
        break;
    }
  }

  void _switchTheme(ThemeMode themeMode) {
    final themeProvider = context.read<ThemeProvider>();

    switch (themeMode) {
      case ThemeMode.dark:
        themeProvider.setDarkTheme();
        break;
      case ThemeMode.light:
        themeProvider.setLightTheme();
        break;
      case ThemeMode.system:
        // For system, detect system preference
        final brightness = MediaQuery.of(context).platformBrightness;
        if (brightness == Brightness.dark) {
          themeProvider.setDarkTheme();
        } else {
          themeProvider.setLightTheme();
        }
        break;
    }

    setState(() {
      _selectedThemeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        text: AppLocalizations.of(context)!.theme,
        context: context,
        hasBackButton: true,
        onTap: () => controller.switchTab('main'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.cardPadding * 3),
              Text(
                AppLocalizations.of(context)!.theme,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildThemeOption(
                    label: "System",
                    icon: Icons.settings_suggest,
                    isActive: _selectedThemeMode == ThemeMode.system,
                    onTap: () => _switchTheme(ThemeMode.system),
                  ),
                  const SizedBox(width: AppTheme.cardPadding),
                  _buildThemeOption(
                    label: AppLocalizations.of(context)!.light,
                    icon: Icons.light_mode,
                    isActive: _selectedThemeMode == ThemeMode.light,
                    onTap: () => _switchTheme(ThemeMode.light),
                  ),
                  const SizedBox(width: AppTheme.cardPadding),
                  _buildThemeOption(
                    label: AppLocalizations.of(context)!.dark,
                    icon: Icons.dark_mode,
                    isActive: _selectedThemeMode == ThemeMode.dark,
                    onTap: () => _switchTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppTheme.cardPadding * 4,
        height: AppTheme.cardPadding * 5.25,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.black60.withValues(alpha: 0.3)
              : AppTheme.white90,
          borderRadius: BorderRadius.circular(AppTheme.cardPadding),
          border: Border.all(
            color: isActive ? AppTheme.colorBitcoin : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isActive
                  ? AppTheme.colorBitcoin
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? AppTheme.colorBitcoin
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.white60
                        : AppTheme.black60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
