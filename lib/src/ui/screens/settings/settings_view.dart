import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/hybrid_logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/screens/onboarding/onboarding_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsView extends StatefulWidget {
  final String aspId;

  const SettingsView({
    super.key,
    required this.aspId,
  });

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  final SettingsService _settingsService = SettingsService();
  bool _wordRecoverySet = false;
  bool _showDeveloperOptions = false;
  bool _isExportingLogs = false;

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
  }

  Future<void> _exportLogs() async {
    setState(() => _isExportingLogs = true);
    try {
      final logFile = await HybridOutput.logFilePath();
      if (await logFile.exists()) {
        final fileSize = await logFile.length();
        final fileSizeKb = (fileSize / 1024).toStringAsFixed(1);

        await Share.shareXFiles(
          [XFile(logFile.path)],
          subject: 'Lenda App Logs',
          text: 'App logs (${fileSizeKb}KB) - Please attach to bug report',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No log file found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export logs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingLogs = false);
      }
    }
  }

  Future<void> _loadRecoveryStatus() async {
    final wordSet = await _settingsService.isWordRecoverySet();
    if (mounted) {
      setState(() {
        _wordRecoverySet = wordSet;
      });
    }
  }

  void _showResetWalletDialog() {
    arkBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              AppLocalizations.of(context)!.resetWallet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              AppLocalizations.of(context)!.thisWillDeleteAllWalletData,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              buttonType: ButtonType.transparent,
              title: AppLocalizations.of(context)!.cancel,
              onTap: () => Navigator.pop(context),
              customWidth: double.infinity,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            LongButtonWidget(
              buttonType: ButtonType.solid,
              title: AppLocalizations.of(context)!.reset,
              onTap: () async {
                var dataDir = await getApplicationSupportDirectory();
                await resetWallet(dataDir: dataDir.path);
                await _settingsService.resetToDefaults();

                // Reset service singletons so they re-initialize with new wallet
                LendaSwapService().reset();
                LendasatService().reset();

                if (context.mounted) {
                  // Navigate to OnboardingScreen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              customWidth: double.infinity,
              backgroundColor: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
          ],
        ),
      ),
    );
  }

  /// Builds the Recovery Options tile with status indicator dot
  /// The dot color indicates recovery setup status:
  /// - Red: No recovery options set up
  /// - Orange: Some recovery options set up
  /// - Green: All recovery options set up
  Widget _buildRecoveryOptionsTile(
    BuildContext context,
    SettingsController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine dot color based on word recovery status
    // (email recovery is disabled/Coming Soon)
    Color recoveryDotColor;
    if (_wordRecoverySet) {
      recoveryDotColor = AppTheme.successColor; // Green for set up
    } else {
      recoveryDotColor = AppTheme.errorColor; // Red for not set up
    }

    return ArkListTile(
      leading: Stack(
        children: [
          RoundedButtonWidget(
            iconData: Icons.security_rounded,
            onTap: () => controller.switchTab('emergency_recovery'),
            size: AppTheme.iconSize * 1.5,
            buttonType: ButtonType.transparent,
          ),
          // Status indicator dot
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recoveryDotColor,
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      text: AppLocalizations.of(context)!.recoveryOptions,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: AppTheme.iconSize * 0.75,
        color: isDark ? AppTheme.white60 : AppTheme.black60,
      ),
      onTap: () => controller.switchTab('emergency_recovery'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        text: AppLocalizations.of(context)!.settings,
        context: context,
        hasBackButton: false,
      ),
      body: ListTileTheme(
        iconColor: Theme.of(context).colorScheme.onSurface,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.elementSpacing * 0.25,
          ),
          child: ListView(
            key: const Key('SettingsListViewContent'),
            children: [
              // Recovery Options (with status indicator dot) - most important
              _buildRecoveryOptionsTile(context, controller),

              // Language
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.language,
                  onTap: () => controller.switchTab('language'),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.language,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
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
                text: AppLocalizations.of(context)!.timezone,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
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
                text: AppLocalizations.of(context)!.currency,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.white60
                              : AppTheme.black60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: AppTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.white60
                            : AppTheme.black60,
                      ),
                    ],
                  ),
                  onTap: () => controller.switchTab('chart_time_range'),
                ),
              ),

              // Legal / AGB & Impressum
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.info_outline,
                  onTap: () => controller.switchTab('agbs'),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.legalInformation,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: () => controller.switchTab('agbs'),
              ),

              // Recovery Key - temporarily disabled (already included in Recovery Options)
              // ArkListTile(
              //   leading: RoundedButtonWidget(
              //     iconData: Icons.key_rounded,
              //     onTap: () => controller.switchTab('recovery'),
              //     size: AppTheme.iconSize * 1.5,
              //     buttonType: ButtonType.transparent,
              //   ),
              //   text: AppLocalizations.of(context)!.viewRecoveryKey,
              //   trailing: Icon(
              //     Icons.arrow_forward_ios_rounded,
              //     size: AppTheme.iconSize * 0.75,
              //     color: Theme.of(context).brightness == Brightness.dark
              //         ? AppTheme.white60
              //         : AppTheme.black60,
              //   ),
              //   onTap: () => controller.switchTab('recovery'),
              // ),

              // Feedback / Report Bug - temporarily disabled
              // ArkListTile(
              //   leading: RoundedButtonWidget(
              //     iconData: Icons.feedback_rounded,
              //     onTap: () => controller.switchTab('feedback'),
              //     size: AppTheme.iconSize * 1.5,
              //     buttonType: ButtonType.transparent,
              //   ),
              //   text: AppLocalizations.of(context)!.reportBugFeedback,
              //   trailing: Icon(
              //     Icons.arrow_forward_ios_rounded,
              //     size: AppTheme.iconSize * 0.75,
              //     color: Theme.of(context).brightness == Brightness.dark
              //         ? AppTheme.white60
              //         : AppTheme.black60,
              //   ),
              //   onTap: () => controller.switchTab('feedback'),
              // ),

              // Claim Gifts - temporarily disabled
              // ArkListTile(
              //   leading: RoundedButtonWidget(
              //     iconData: Icons.card_giftcard_rounded,
              //     onTap: () => controller.switchTab('claim_sats'),
              //     size: AppTheme.iconSize * 1.5,
              //     buttonType: ButtonType.transparent,
              //   ),
              //   text: 'Claim Gifts',
              //   trailing: Icon(
              //     Icons.arrow_forward_ios_rounded,
              //     size: AppTheme.iconSize * 0.75,
              //     color: Theme.of(context).brightness == Brightness.dark
              //         ? AppTheme.white60
              //         : AppTheme.black60,
              //   ),
              //   onTap: () => controller.switchTab('claim_sats'),
              // ),

              // Reset Wallet
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.warning_amber_rounded,
                  onTap: _showResetWalletDialog,
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.resetWallet,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: _showResetWalletDialog,
              ),

              const SizedBox(height: AppTheme.cardPadding),

              // Developer Options
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.code_rounded,
                  onTap: () => setState(
                      () => _showDeveloperOptions = !_showDeveloperOptions),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: 'Developer Options',
                trailing: Icon(
                  _showDeveloperOptions
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: AppTheme.iconSize,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: () => setState(
                    () => _showDeveloperOptions = !_showDeveloperOptions),
              ),

              // Developer Options Content
              if (_showDeveloperOptions) ...[
                Padding(
                  padding: const EdgeInsets.only(left: AppTheme.cardPadding),
                  child: Column(
                    children: [
                      // Export Logs
                      ArkListTile(
                        leading: _isExportingLogs
                            ? const SizedBox(
                                width: AppTheme.iconSize * 1.5,
                                height: AppTheme.iconSize * 1.5,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : RoundedButtonWidget(
                                iconData: Icons.description_outlined,
                                onTap: _exportLogs,
                                size: AppTheme.iconSize * 1.5,
                                buttonType: ButtonType.transparent,
                              ),
                        text: 'Export Logs',
                        trailing: Icon(
                          Icons.share_rounded,
                          size: AppTheme.iconSize * 0.75,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.white60
                              : AppTheme.black60,
                        ),
                        onTap: _isExportingLogs ? null : _exportLogs,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.cardPadding * 2),
            ],
          ),
        ),
      ),
    );
  }
}
