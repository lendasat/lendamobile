import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:restart_app/restart_app.dart';
import 'package:ark_flutter/app_theme.dart';
import 'change_style_screen.dart';
import 'change_language_screen.dart';
import 'change_timezone_screen.dart';
import 'change_currency_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String aspId;

  const SettingsScreen({
    super.key,
    required this.aspId,
  });

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String _nsec = 'Unknown';
  Info? _info;
  String _selectedNetwork = 'Regtest';

  // Create an instance of SettingsService
  final SettingsService _settingsService = SettingsService();

  // Text editing controllers for URL inputs
  final TextEditingController _esploraUrlController = TextEditingController();
  final TextEditingController _arkServerController = TextEditingController();
  final TextEditingController _boltzUrlController = TextEditingController();

  final List<String> _supportedNetworks = ['bitcoin', 'signet', 'regtest'];

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNsec();
    _fetchInfo();
    _loadSettings();
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    try {
      final esploraUrl = await _settingsService.getEsploraUrl();
      final arkServerUrl = await _settingsService.getArkServerUrl();
      final network = await _settingsService.getNetwork();
      final boltzUrl = await _settingsService.getBoltzUrl();

      setState(() {
        _esploraUrlController.text = esploraUrl;
        _arkServerController.text = arkServerUrl;
        _boltzUrlController.text = boltzUrl;
        _selectedNetwork = network;
        _isLoading = false;
      });
    } catch (err) {
      logger.e("Error loading settings: $err");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNsec() async {
    try {
      var dataDir = await getApplicationSupportDirectory();
      var key = await nsec(dataDir: dataDir.path);
      setState(() {
        _nsec = key;
      });
    } catch (err) {
      logger.e("Error getting nsec: $err");
    }
  }

  Future<void> _fetchInfo() async {
    try {
      var info = await information();

      setState(() {
        _info = info;
      });
    } catch (err) {
      logger.e("Error getting info: $err");
    }
  }

  // Save Esplora URL
  Future<void> _saveEsploraUrl() async {
    try {
      await _settingsService.saveEsploraUrl(_esploraUrlController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .esploraUrlSavedWillOnlyTakeEffectAfterARestart)),
        );
      }
      logger.i("Esplora URL saved: ${_esploraUrlController.text}");
    } catch (err) {
      logger.e("Error saving Esplora URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.failedToSaveEsploraUrl)),
        );
      }
    }
  }

  // Save Network URL
  Future<void> _saveNetwork(String network) async {
    try {
      await _settingsService.saveNetwork(network);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .networkSavedWillOnlyTakeEffectAfterARestart)),
        );
      }
      logger.i("Esplora URL saved: ${_esploraUrlController.text}");
    } catch (err) {
      logger.e("Error saving Esplora URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.failedToSaveEsploraUrl)),
        );
      }
    }
  }

  // Save Ark Server URL
  Future<void> _saveArkServerUrl() async {
    try {
      await _settingsService.saveArkServerUrl(_arkServerController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .arkServerUrlSavedWillOnlyTakeEffectAfterARestart)),
        );
      }
      logger.i("Ark Server URL saved: ${_arkServerController.text}");
    } catch (err) {
      logger.e("Error saving Ark Server URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.failedToSaveArkServerUrl)),
        );
      }
    }
  }

  // Save Boltz URL
  Future<void> _saveBoltzUrl() async {
    try {
      await _settingsService.saveBoltzUrl(_boltzUrlController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .boltzUrlSavedWillOnlyTakeEffectAfterARestart)),
        );
      }
      logger.i("Boltz URL saved: ${_boltzUrlController.text}");
    } catch (err) {
      logger.e("Error saving Boltz URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.failedToSaveBoltzUrl)),
        );
      }
    }
  }

  @override
  void dispose() {
    _esploraUrlController.dispose();
    _arkServerController.dispose();
    _boltzUrlController.dispose();
    super.dispose();
  }

  void _showBackupWarningDialog() {
    final theme = AppTheme.of(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.secondaryBlack,
        title: Text(
          AppLocalizations.of(context)!.securityWarning,
          style: const TextStyle(color: Colors.amber),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.neverShareYourRecoveryKeyWithAnyone,
              style: TextStyle(
                  color: theme.primaryWhite, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.anyoneWithThisKeyCan,
              style: TextStyle(color: theme.mutedText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: theme.mutedText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRecoveryKeyDialog();
            },
            child: Text(AppLocalizations.of(context)!.iUnderstand,
                style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showRecoveryKeyDialog() {
    final theme = AppTheme.of(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.secondaryBlack,
        title: Text(AppLocalizations.of(context)!.yourRecoveryPhrase,
            style: TextStyle(color: theme.primaryWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.tertiaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.secondaryBlack,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _nsec,
                        style: TextStyle(
                          color: theme.primaryWhite,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _nsec));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .recoveryPhraseCopiedToClipboard)),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.amber),
              label: Text(AppLocalizations.of(context)!.copyToClipboard),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close,
                style: TextStyle(color: theme.primaryWhite)),
          ),
        ],
      ),
    );
  }

  void _showResetWalletDialog() {
    final theme = AppTheme.of(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.secondaryBlack,
        title: Text(AppLocalizations.of(context)!.resetWallet,
            style: const TextStyle(color: Colors.red)),
        content: Text(
          AppLocalizations.of(context)!.thisWillDeleteAllWalletData,
          style: TextStyle(color: theme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: theme.primaryWhite)),
          ),
          TextButton(
            onPressed: () async {
              // Reset wallet
              var dataDir = await getApplicationSupportDirectory();
              await resetWallet(dataDir: dataDir.path);

              // Reset settings to defaults
              await _settingsService.resetToDefaults();

              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(content: Text('Wallet reseted - exiting application')),
              // );
              if (context.mounted) {
                Restart.restartApp(
                  /// In Web Platform, Fill webOrigin only when your new origin is different than the app's origin
                  // webOrigin: 'http://example.com',

                  // Customizing the notification message only on iOS
                  notificationTitle:
                      AppLocalizations.of(context)!.restartingApp,
                  notificationBody: AppLocalizations.of(context)!
                      .pleaseTapHereToOpenTheAppAgain,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.reset,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            color: theme.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Wallet Settings Section
                _buildSectionHeader(AppLocalizations.of(context)!.wallet),
                _buildSettingsCard([
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.viewRecoveryKey,
                        style: TextStyle(color: theme.primaryWhite)),
                    subtitle: Text(
                      AppLocalizations.of(context)!
                          .backupYourWalletWithTheseKey,
                      style: TextStyle(color: theme.mutedText, fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right, color: theme.mutedText),
                    onTap: _showBackupWarningDialog,
                  ),
                ]),

                const SizedBox(height: 24),

                // Appearance & Preferences Section
                _buildSectionHeader(
                    AppLocalizations.of(context)!.appearancePreferences),
                _buildSettingsCard([
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.theme,
                        style: TextStyle(color: theme.primaryWhite)),
                    subtitle: Text(
                      AppLocalizations.of(context)!.customizeAppAppearance,
                      style: TextStyle(color: theme.mutedText, fontSize: 12),
                    ),
                    leading: const Icon(Icons.palette, color: Colors.amber),
                    trailing: Icon(Icons.chevron_right, color: theme.mutedText),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeStyleScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.language,
                        style: TextStyle(color: theme.primaryWhite)),
                    subtitle: Text(
                      AppLocalizations.of(context)!.selectYourPreferredLanguage,
                      style: TextStyle(color: theme.mutedText, fontSize: 12),
                    ),
                    leading: const Icon(Icons.language, color: Colors.amber),
                    trailing: Icon(Icons.chevron_right, color: theme.mutedText),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeLanguageScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.timezone,
                        style: TextStyle(color: theme.primaryWhite)),
                    subtitle: Text(
                      AppLocalizations.of(context)!.chooseYourPreferredTimezone,
                      style: TextStyle(color: theme.mutedText, fontSize: 12),
                    ),
                    leading: const Icon(Icons.public, color: Colors.amber),
                    trailing: Icon(Icons.chevron_right, color: theme.mutedText),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeTimezoneScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.currency,
                        style: TextStyle(color: theme.primaryWhite)),
                    subtitle: Text(
                      AppLocalizations.of(context)!.chooseYourPreferredCurrency,
                      style: TextStyle(color: theme.mutedText, fontSize: 12),
                    ),
                    leading:
                        const Icon(Icons.attach_money, color: Colors.amber),
                    trailing: Icon(Icons.chevron_right, color: theme.mutedText),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeCurrencyScreen(),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // Server Settings Section
                _buildSectionHeader(
                    AppLocalizations.of(context)!.serverConfiguration),
                _buildSettingsCard([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      title: Text(AppLocalizations.of(context)!.network,
                          style: TextStyle(color: theme.primaryWhite)),
                      trailing: DropdownButton<String>(
                        value: _selectedNetwork,
                        dropdownColor: theme.tertiaryBlack,
                        underline: const SizedBox(),
                        icon:
                            Icon(Icons.arrow_drop_down, color: theme.mutedText),
                        style: const TextStyle(color: Colors.amber),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedNetwork = value;
                            });
                            _saveNetwork(value);
                            logger.i("Network changed to: $value");
                          }
                        },
                        items: _supportedNetworks
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.esploraUrl,
                          style: TextStyle(
                              color: theme.primaryWhite, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _esploraUrlController,
                          style: TextStyle(color: theme.primaryWhite),
                          decoration: InputDecoration(
                            hintText: SettingsService.defaultEsploraUrl,
                            hintStyle: TextStyle(color: theme.subtleText),
                            filled: true,
                            fillColor: theme.tertiaryBlack,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save, color: Colors.amber),
                              onPressed: _saveEsploraUrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.arkServer,
                          style: TextStyle(
                              color: theme.primaryWhite, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _arkServerController,
                          style: TextStyle(color: theme.primaryWhite),
                          decoration: InputDecoration(
                            hintText: SettingsService.defaultArkServerUrl,
                            hintStyle: TextStyle(color: theme.subtleText),
                            filled: true,
                            fillColor: theme.tertiaryBlack,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save, color: Colors.amber),
                              onPressed: _saveArkServerUrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.boltzUrl,
                          style: TextStyle(
                              color: theme.primaryWhite, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _boltzUrlController,
                          style: TextStyle(color: theme.primaryWhite),
                          decoration: InputDecoration(
                            hintText: SettingsService.defaultBoltzUrl,
                            hintStyle: TextStyle(color: theme.subtleText),
                            filled: true,
                            fillColor: theme.tertiaryBlack,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save, color: Colors.amber),
                              onPressed: _saveBoltzUrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader(AppLocalizations.of(context)!.about),
                _buildSettingsCard([
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.network,
                        style: TextStyle(color: theme.primaryWhite)),
                    subtitle: _info != null
                        ? Text(
                            _info!.network,
                            style:
                                TextStyle(color: theme.mutedText, fontSize: 12),
                          )
                        : Text(AppLocalizations.of(context)!.loading,
                            style: TextStyle(
                                color: theme.mutedText, fontSize: 12)),
                  ),
                ]),

                const SizedBox(height: 32),

                // Danger Zone
                _buildSectionHeader(AppLocalizations.of(context)!.dangerZone,
                    color: Colors.red),
                _buildSettingsCard([
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.resetWallet,
                        style: const TextStyle(color: Colors.red)),
                    subtitle: Text(
                      AppLocalizations.of(context)!
                          .deleteAllWalletDataFromThisDevice,
                      style: TextStyle(color: theme.mutedText, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.warning_amber_rounded,
                        color: Colors.red),
                    onTap: _showResetWalletDialog,
                  ),
                ], borderColor: Colors.red.withAlpha((0.3 * 255).round())),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.amber,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children,
      {Color borderColor = Colors.transparent}) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: borderColor != Colors.transparent ? 1 : 0,
        ),
      ),
      child: Column(
        children: [
          ...children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;

            if (index < children.length - 1) {
              return Column(
                children: [
                  child,
                  Divider(
                    color: theme.borderColor,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],
              );
            } else {
              return child;
            }
          }),
        ],
      ),
    );
  }
}
