import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:provider/provider.dart';

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
  String _nsec = 'Unknown';
  Info? _info;
  String _selectedNetwork = 'Regtest';

  final SettingsService _settingsService = SettingsService();
  final TextEditingController _esploraUrlController = TextEditingController();
  final TextEditingController _arkServerController = TextEditingController();
  final TextEditingController _boltzUrlController = TextEditingController();

  final List<String> _supportedNetworks = ['bitcoin', 'signet', 'regtest'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNsec();
    _fetchInfo();
    _loadSettings();
  }

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

  Future<void> _saveEsploraUrl() async {
    try {
      await _settingsService.saveEsploraUrl(_esploraUrlController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .esploraUrlSavedWillOnlyTakeEffectAfterARestart),
          ),
        );
      }
      logger.i("Esplora URL saved: ${_esploraUrlController.text}");
    } catch (err) {
      logger.e("Error saving Esplora URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSaveEsploraUrl),
          ),
        );
      }
    }
  }

  Future<void> _saveNetwork(String network) async {
    try {
      await _settingsService.saveNetwork(network);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .networkSavedWillOnlyTakeEffectAfterARestart),
          ),
        );
      }
      logger.i("Network saved: $network");
    } catch (err) {
      logger.e("Error saving network: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSaveEsploraUrl),
          ),
        );
      }
    }
  }

  Future<void> _saveArkServerUrl() async {
    try {
      await _settingsService.saveArkServerUrl(_arkServerController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .arkServerUrlSavedWillOnlyTakeEffectAfterARestart),
          ),
        );
      }
      logger.i("Ark Server URL saved: ${_arkServerController.text}");
    } catch (err) {
      logger.e("Error saving Ark Server URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.failedToSaveArkServerUrl),
          ),
        );
      }
    }
  }

  Future<void> _saveBoltzUrl() async {
    try {
      await _settingsService.saveBoltzUrl(_boltzUrlController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .boltzUrlSavedWillOnlyTakeEffectAfterARestart),
          ),
        );
      }
      logger.i("Boltz URL saved: ${_boltzUrlController.text}");
    } catch (err) {
      logger.e("Error saving Boltz URL: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSaveBoltzUrl),
          ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? BitNetTheme.black90
            : Colors.white,
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.white90
                    : BitNetTheme.black90,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.anyoneWithThisKeyCan,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.white60
                    : BitNetTheme.black60,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.white60
                    : BitNetTheme.black60,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRecoveryKeyDialog();
            },
            child: Text(
              AppLocalizations.of(context)!.iUnderstand,
              style: const TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecoveryKeyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? BitNetTheme.black90
            : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.yourRecoveryPhrase,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? BitNetTheme.white90
                : BitNetTheme.black90,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.black60.withValues(alpha: 0.3)
                    : BitNetTheme.white90,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white60.withValues(alpha: 0.2)
                      : BitNetTheme.black60.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.black90
                            : BitNetTheme.white90,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _nsec,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? BitNetTheme.white90
                              : BitNetTheme.black90,
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
            child: Text(
              AppLocalizations.of(context)!.close,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.white90
                    : BitNetTheme.black90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? BitNetTheme.black90
            : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.resetWallet,
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          AppLocalizations.of(context)!.thisWillDeleteAllWalletData,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? BitNetTheme.white60
                : BitNetTheme.black60,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.white90
                    : BitNetTheme.black90,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              var dataDir = await getApplicationSupportDirectory();
              await resetWallet(dataDir: dataDir.path);
              await _settingsService.resetToDefaults();

              if (context.mounted) {
                Restart.restartApp(
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
            child: Text(
              AppLocalizations.of(context)!.reset,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? BitNetTheme.black90
            : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.serverConfiguration,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? BitNetTheme.white90
                : BitNetTheme.black90,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.network,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BitNetTheme.white90
                          : BitNetTheme.black90,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedNetwork,
                    dropdownColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.black90
                            : Colors.white,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BitNetTheme.white60
                          : BitNetTheme.black60,
                    ),
                    style: const TextStyle(color: Colors.amber),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedNetwork = value;
                        });
                        _saveNetwork(value);
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
                ],
              ),
              const SizedBox(height: 16),

              // Esplora URL
              Text(
                AppLocalizations.of(context)!.esploraUrl,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white90
                      : BitNetTheme.black90,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _esploraUrlController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white90
                      : BitNetTheme.black90,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: SettingsService.defaultEsploraUrl,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BitNetTheme.white60
                        : BitNetTheme.black60,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.black60.withValues(alpha: 0.3)
                      : BitNetTheme.white90,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: Colors.amber, size: 20),
                    onPressed: _saveEsploraUrl,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ark Server URL
              Text(
                AppLocalizations.of(context)!.arkServer,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white90
                      : BitNetTheme.black90,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _arkServerController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white90
                      : BitNetTheme.black90,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: SettingsService.defaultArkServerUrl,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BitNetTheme.white60
                        : BitNetTheme.black60,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.black60.withValues(alpha: 0.3)
                      : BitNetTheme.white90,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: Colors.amber, size: 20),
                    onPressed: _saveArkServerUrl,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Boltz URL
              Text(
                AppLocalizations.of(context)!.boltzUrl,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white90
                      : BitNetTheme.black90,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _boltzUrlController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.white90
                      : BitNetTheme.black90,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: SettingsService.defaultBoltzUrl,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BitNetTheme.white60
                        : BitNetTheme.black60,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? BitNetTheme.black60.withValues(alpha: 0.3)
                      : BitNetTheme.white90,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: Colors.amber, size: 20),
                    onPressed: _saveBoltzUrl,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Network info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.network,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BitNetTheme.white90
                          : BitNetTheme.black90,
                    ),
                  ),
                  Text(
                    _info?.network ?? AppLocalizations.of(context)!.loading,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BitNetTheme.white60
                          : BitNetTheme.black60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BitNetTheme.white90
                    : BitNetTheme.black90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: AppLocalizations.of(context)!.settings,
        context: context,
        hasBackButton: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            )
          : ListTileTheme(
              iconColor: Theme.of(context).colorScheme.onSurface,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: BitNetTheme.elementSpacing * 0.25,
                ),
                child: ListView(
                  key: const Key('SettingsListViewContent'),
                  children: [
                    // Theme
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.color_lens,
                        onTap: () => controller.switchTab('style'),
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.theme,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.white60
                            : BitNetTheme.black60,
                      ),
                      onTap: () => controller.switchTab('style'),
                    ),

                    // Language
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.language,
                        onTap: () => controller.switchTab('language'),
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.language,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.white60
                            : BitNetTheme.black60,
                      ),
                      onTap: () => controller.switchTab('language'),
                    ),

                    // Timezone
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.access_time_rounded,
                        onTap: () => controller.switchTab('timezone'),
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.timezone,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.white60
                            : BitNetTheme.black60,
                      ),
                      onTap: () => controller.switchTab('timezone'),
                    ),

                    // Currency
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.currency_bitcoin,
                        onTap: () => controller.switchTab('currency'),
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.currency,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.white60
                            : BitNetTheme.black60,
                      ),
                      onTap: () => controller.switchTab('currency'),
                    ),

                    // Recovery Key
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.key_rounded,
                        onTap: _showBackupWarningDialog,
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.viewRecoveryKey,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.white60
                            : BitNetTheme.black60,
                      ),
                      onTap: _showBackupWarningDialog,
                    ),

                    // Developer Options
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.developer_mode_outlined,
                        onTap: _showDeveloperOptionsDialog,
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.serverConfiguration,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? BitNetTheme.white60
                            : BitNetTheme.black60,
                      ),
                      onTap: _showDeveloperOptionsDialog,
                    ),

                    // Reset Wallet
                    ArkListTile(
                      leading: RoundedButtonWidget(
                        iconData: Icons.warning_amber_rounded,
                        onTap: _showResetWalletDialog,
                        size: BitNetTheme.iconSize * 1.5,
                        buttonType: ButtonType.transparent,
                      ),
                      text: AppLocalizations.of(context)!.resetWallet,
                      titleStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: BitNetTheme.iconSize * 0.75,
                        color: Colors.red.withValues(alpha: 0.6),
                      ),
                      onTap: _showResetWalletDialog,
                    ),

                    const SizedBox(height: BitNetTheme.cardPadding * 2),
                  ],
                ),
              ),
            ),
    );
  }
}
