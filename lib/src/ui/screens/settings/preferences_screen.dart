import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/biometric_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Preferences Screen - displays app preferences and settings
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _isBiometricLoading = false;

  Future<void> _handleBiometricToggle(
      BiometricService biometricService, bool enable) async {
    if (_isBiometricLoading) return;

    setState(() => _isBiometricLoading = true);

    try {
      final success = await biometricService.setEnabled(enable);

      if (!success && enable && mounted) {
        // Show error if enabling failed
        OverlayService().showError(
          'Could not enable biometric authentication. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        OverlayService().showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffoldUnsafe(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        text: l10n.preferences,
        context: context,
        hasBackButton: true,
        onTap: () => controller.resetToMain(),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing * 0.25,
        ),
        child: ListView(
          children: [
            const SizedBox(height: AppTheme.cardPadding),

            // Language
            ArkListTile(
              leading: RoundedButtonWidget(
                iconData: Icons.language,
                onTap: () => controller.switchTab('language'),
                size: AppTheme.iconSize * 1.5,
                buttonType: ButtonType.transparent,
              ),
              text: l10n.language,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppTheme.iconSize * 0.75,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
              onTap: () => controller.switchTab('language'),
            ),

            // Timezone
            ArkListTile(
              leading: RoundedButtonWidget(
                iconData: Icons.access_time_rounded,
                onTap: () => controller.switchTab('timezone'),
                size: AppTheme.iconSize * 1.5,
                buttonType: ButtonType.transparent,
              ),
              text: l10n.timezone,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppTheme.iconSize * 0.75,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
              onTap: () => controller.switchTab('timezone'),
            ),

            // Currency
            ArkListTile(
              leading: RoundedButtonWidget(
                iconData: Icons.currency_bitcoin,
                onTap: () => controller.switchTab('currency'),
                size: AppTheme.iconSize * 1.5,
                buttonType: ButtonType.transparent,
              ),
              text: l10n.currency,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppTheme.iconSize * 0.75,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
              onTap: () => controller.switchTab('currency'),
            ),

            // Chart Time Range
            Consumer<UserPreferencesService>(
              builder: (context, userPrefs, _) => ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.show_chart_rounded,
                  onTap: () => controller.switchTab('chart_time_range'),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: 'Chart Time Range',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userPrefs.getChartTimeRangeLabel(),
                      style: TextStyle(
                        color: isDark ? AppTheme.white60 : AppTheme.black60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: AppTheme.iconSize * 0.75,
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ],
                ),
                onTap: () => controller.switchTab('chart_time_range'),
              ),
            ),

            // Auto-read clipboard
            Consumer<UserPreferencesService>(
              builder: (context, userPrefs, _) => ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.content_paste_rounded,
                  onTap: () => userPrefs.toggleAutoReadClipboard(),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: l10n.autoReadClipboard,
                trailing: Switch.adaptive(
                  value: userPrefs.autoReadClipboard,
                  onChanged: (value) => userPrefs.setAutoReadClipboard(value),
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () => userPrefs.toggleAutoReadClipboard(),
              ),
            ),

            // Allow Analytics
            Consumer<UserPreferencesService>(
              builder: (context, userPrefs, _) => ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.analytics_outlined,
                  onTap: () => userPrefs.toggleAllowAnalytics(),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: 'Allow Analytics',
                trailing: Switch.adaptive(
                  value: userPrefs.allowAnalytics,
                  onChanged: (value) => userPrefs.setAllowAnalytics(value),
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: () => userPrefs.toggleAllowAnalytics(),
              ),
            ),

            const SizedBox(height: AppTheme.cardPadding),

            // Security Section Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing,
                vertical: AppTheme.elementSpacing / 2,
              ),
              child: Text(
                'Security',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Biometric Authentication
            Consumer<BiometricService>(
              builder: (context, biometricService, _) {
                final isAvailable = biometricService.isAvailable;
                final biometricName = biometricService.getBiometricTypeName();
                final canInteract = isAvailable && !_isBiometricLoading;

                return ArkListTile(
                  leading: _isBiometricLoading
                      ? SizedBox(
                          width: AppTheme.iconSize * 1.5,
                          height: AppTheme.iconSize * 1.5,
                          child: dotProgress(context, size: 16),
                        )
                      : RoundedButtonWidget(
                          iconData: Icons.fingerprint_rounded,
                          onTap: canInteract
                              ? () => _handleBiometricToggle(
                                    biometricService,
                                    !biometricService.isEnabled,
                                  )
                              : null,
                          size: AppTheme.iconSize * 1.5,
                          buttonType: ButtonType.transparent,
                        ),
                  text: biometricName,
                  subtitle: Text(
                    isAvailable
                        ? 'Require $biometricName to open app'
                        : 'Not available on this device',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable
                          ? (isDark ? AppTheme.white60 : AppTheme.black60)
                          : AppTheme.errorColor.withValues(alpha: 0.7),
                    ),
                  ),
                  trailing: _isBiometricLoading
                      ? SizedBox(
                          width: 48,
                          height: 24,
                          child: Center(
                            child: dotProgress(context, size: 12),
                          ),
                        )
                      : Switch.adaptive(
                          value: biometricService.isEnabled,
                          onChanged: canInteract
                              ? (value) => _handleBiometricToggle(
                                    biometricService,
                                    value,
                                  )
                              : null,
                          activeColor: AppTheme.primaryColor,
                        ),
                  onTap: canInteract
                      ? () => _handleBiometricToggle(
                            biometricService,
                            !biometricService.isEnabled,
                          )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
