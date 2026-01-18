import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/hybrid_logger.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
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
  bool _showPreferences = false;
  bool _isExportingLogs = false;
  bool _isLoadingVtxoBalance = false;
  bool _isSettling = false;

  // Environment info
  String _esploraUrl = '';
  String _arkServerUrl = '';
  String _arkNetwork = '';
  String _boltzUrl = '';
  String _backendUrl = '';
  String _websiteUrl = '';

  // VTXO Balance breakdown
  BigInt _pendingSats = BigInt.zero;
  BigInt _confirmedSats = BigInt.zero;
  BigInt _expiredSats = BigInt.zero;
  BigInt _recoverableSats = BigInt.zero;
  BigInt _totalSats = BigInt.zero;

  // App version info
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
    _loadEnvironmentInfo();
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

  Future<void> _loadVtxoBalance() async {
    if (_isLoadingVtxoBalance) return;
    setState(() => _isLoadingVtxoBalance = true);
    try {
      final balanceResult = await balance();
      debugPrint('VTXO Balance: pending=${balanceResult.offchain.pendingSats}, '
          'confirmed=${balanceResult.offchain.confirmedSats}, '
          'expired=${balanceResult.offchain.expiredSats}, '
          'recoverable=${balanceResult.offchain.recoverableSats}, '
          'total=${balanceResult.offchain.totalSats}');
      if (mounted) {
        setState(() {
          _pendingSats = balanceResult.offchain.pendingSats;
          _confirmedSats = balanceResult.offchain.confirmedSats;
          _expiredSats = balanceResult.offchain.expiredSats;
          _recoverableSats = balanceResult.offchain.recoverableSats;
          _totalSats = balanceResult.offchain.totalSats;
        });
      }
    } catch (e) {
      debugPrint('Error loading VTXO balance: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVtxoBalance = false);
      }
    }
  }

  Future<void> _manualSettle() async {
    if (_isSettling) return;
    setState(() => _isSettling = true);
    try {
      debugPrint('Manual settle triggered...');
      await settle();
      debugPrint('Manual settle completed!');
      // Refresh balance after settle
      await _loadVtxoBalance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settle completed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during manual settle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settle failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettling = false);
      }
    }
  }

  Future<void> _loadEnvironmentInfo() async {
    final esploraUrl = await _settingsService.getEsploraUrl();
    final arkServerUrl = await _settingsService.getArkServerUrl();
    final arkNetwork = await _settingsService.getNetwork();
    final boltzUrl = await _settingsService.getBoltzUrl();
    final backendUrl = await _settingsService.getBackendUrl();
    final websiteUrl = await _settingsService.getWebsiteUrl();

    if (mounted) {
      setState(() {
        _esploraUrl = esploraUrl;
        _arkServerUrl = arkServerUrl;
        _arkNetwork = arkNetwork;
        _boltzUrl = boltzUrl;
        _backendUrl = backendUrl;
        _websiteUrl = websiteUrl;
      });
    }
  }

  Future<void> _exportLogs() async {
    setState(() => _isExportingLogs = true);
    try {
      final logFile = await HybridOutput.logFilePath();
      if (await logFile.exists()) {
        final fileSize = await logFile.length();
        final fileSizeKb = (fileSize / 1024).toStringAsFixed(1);

        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(logFile.path)],
          subject: 'Lenda App Logs',
          text: 'App logs (${fileSizeKb}KB) - Please attach to bug report',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 100),
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

  Widget _buildEnvInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(not set)' : value,
              style: TextStyle(
                fontSize: 11,
                color: value.isEmpty
                    ? AppTheme.errorColor
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVtxoBalanceRow(String label, BigInt sats, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = sats > BigInt.zero;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$sats sats',
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                color: color ?? (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
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

              // Preferences Section (collapsible)
              ArkListTile(
                leading: RoundedButtonWidget(
                  iconData: Icons.tune_rounded,
                  onTap: () =>
                      setState(() => _showPreferences = !_showPreferences),
                  size: AppTheme.iconSize * 1.5,
                  buttonType: ButtonType.transparent,
                ),
                text: AppLocalizations.of(context)!.preferences,
                trailing: Icon(
                  _showPreferences
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: AppTheme.iconSize,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white60
                      : AppTheme.black60,
                ),
                onTap: () =>
                    setState(() => _showPreferences = !_showPreferences),
              ),

              // Preferences Content
              if (_showPreferences) ...[
                Padding(
                  padding: const EdgeInsets.only(left: AppTheme.cardPadding),
                  child: Column(
                    children: [
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
                            onTap: () =>
                                controller.switchTab('chart_time_range'),
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
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppTheme.white60
                                      : AppTheme.black60,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: AppTheme.iconSize * 0.75,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.white60
                                    : AppTheme.black60,
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
                          text: AppLocalizations.of(context)!.autoReadClipboard,
                          trailing: Switch.adaptive(
                            value: userPrefs.autoReadClipboard,
                            onChanged: (value) =>
                                userPrefs.setAutoReadClipboard(value),
                            activeColor: AppTheme.primaryColor,
                          ),
                          onTap: () => userPrefs.toggleAutoReadClipboard(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                  onTap: () {
                    setState(
                        () => _showDeveloperOptions = !_showDeveloperOptions);
                    if (_showDeveloperOptions) _loadVtxoBalance();
                  },
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
                onTap: () {
                  setState(
                      () => _showDeveloperOptions = !_showDeveloperOptions);
                  if (_showDeveloperOptions) _loadVtxoBalance();
                },
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
                            ? SizedBox(
                                width: AppTheme.iconSize * 1.5,
                                height: AppTheme.iconSize * 1.5,
                                child: dotProgressSmall(context),
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

                      // Environment Info
                      const SizedBox(height: AppTheme.elementSpacing),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.elementSpacing),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Environment Info',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppTheme.elementSpacing),
                            _buildEnvInfoRow('ARK_NETWORK', _arkNetwork),
                            _buildEnvInfoRow('ARK_SERVER_URL', _arkServerUrl),
                            _buildEnvInfoRow('ESPLORA_URL', _esploraUrl),
                            _buildEnvInfoRow('BOLTZ_URL', _boltzUrl),
                            _buildEnvInfoRow('BACKEND_URL', _backendUrl),
                            _buildEnvInfoRow('WEBSITE_URL', _websiteUrl),
                          ],
                        ),
                      ),

                      // VTXO Balance Breakdown
                      const SizedBox(height: AppTheme.elementSpacing),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.elementSpacing),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'VTXO Balance Breakdown',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                GestureDetector(
                                  onTap: _loadVtxoBalance,
                                  child: _isLoadingVtxoBalance
                                      ? dotProgressSmall(context)
                                      : Icon(
                                          Icons.refresh_rounded,
                                          size: 18,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppTheme.white60
                                              : AppTheme.black60,
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.elementSpacing),
                            _buildVtxoBalanceRow('Pending', _pendingSats),
                            _buildVtxoBalanceRow('Confirmed', _confirmedSats,
                                color: AppTheme.successColor),
                            _buildVtxoBalanceRow('Expired', _expiredSats,
                                color: _expiredSats > BigInt.zero
                                    ? AppTheme.colorBitcoin
                                    : null),
                            _buildVtxoBalanceRow(
                                'Recoverable', _recoverableSats,
                                color: _recoverableSats > BigInt.zero
                                    ? AppTheme.colorBitcoin
                                    : null),
                            const Divider(height: 12),
                            _buildVtxoBalanceRow('Total', _totalSats,
                                color: AppTheme.primaryColor),
                            if (_expiredSats > BigInt.zero ||
                                _recoverableSats > BigInt.zero ||
                                _pendingSats > BigInt.zero) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Note: Pending/Expired/Recoverable VTXOs can be consolidated via settle',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.colorBitcoin,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppTheme.elementSpacing),
                            // Settle Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSettling ? null : _manualSettle,
                                icon: _isSettling
                                    ? dotProgressSmall(context)
                                    : const Icon(Icons.sync_rounded, size: 18),
                                label: Text(_isSettling
                                    ? 'Settling...'
                                    : 'Settle VTXOs'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.colorBitcoin,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.borderRadiusSmall),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
