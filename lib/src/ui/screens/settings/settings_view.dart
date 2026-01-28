import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // App version info
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
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

  Future<void> _openFeedbackTelegram() async {
    final uri = Uri.parse('https://t.me/+6TLWEwib3nw0ZWFi');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            Row(
              children: [
                Expanded(
                  child: LongButtonWidget(
                    buttonType: ButtonType.transparent,
                    title: AppLocalizations.of(context)!.cancel,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: LongButtonWidget(
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
                    backgroundColor: AppTheme.errorColor,
                  ),
                ),
              ],
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

    return ArkScaffoldUnsafe(
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

              // Preferences
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.tune_rounded,
                  onTap: () => controller.switchTab('preferences'),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.preferences,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: () => controller.switchTab('preferences'),
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

              // Feedback / Report Bug
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: FontAwesomeIcons.telegram,
                  onTap: _openFeedbackTelegram,
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.reportBugFeedback,
                trailing: Icon(
                  Icons.open_in_new_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: _openFeedbackTelegram,
              ),

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

              // Loans & Contracts
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: FontAwesomeIcons.handHoldingDollar,
                  onTap: () => controller.switchTab('loans'),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.loansAndContracts,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: () => controller.switchTab('loans'),
              ),

              // Developer Options
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.code_rounded,
                  onTap: () => controller.switchTab('developer_options'),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: 'Developer Options',
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppTheme.iconSize * 0.75,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: () => controller.switchTab('developer_options'),
              ),

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

              const SizedBox(height: AppTheme.cardPadding * 2),

              // Version footer
              if (_appVersion.isNotEmpty)
                Center(
                  child: Text(
                    'v$_appVersion ($_buildNumber)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.white60
                          : AppTheme.black60,
                    ),
                  ),
                ),

              const SizedBox(height: AppTheme.cardPadding),
            ],
          ),
        ),
      ),
    );
  }
}
