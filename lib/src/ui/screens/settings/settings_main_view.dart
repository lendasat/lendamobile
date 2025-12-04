import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:restart_app/restart_app.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:provider/provider.dart';

class SettingsMainView extends StatefulWidget {
  final String aspId;

  const SettingsMainView({
    super.key,
    required this.aspId,
  });

  @override
  SettingsMainViewState createState() => SettingsMainViewState();
}

class SettingsMainViewState extends State<SettingsMainView> {
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
    final controller = context.read<SettingsController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: theme.primaryWhite),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              children: [
                _buildSectionHeader(
                    AppLocalizations.of(context)!.appearancePreferences),
                const SizedBox(height: AppTheme.paddingS),
                GlassContainer(
                  child: Column(
                    children: [
                      _buildSettingsListTile(
                        icon: Icons.palette,
                        title: AppLocalizations.of(context)!.theme,
                        onTap: () => controller.switchTab('style'),
                      ),
                      _buildDivider(theme),
                      _buildSettingsListTile(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.language,
                        onTap: () => controller.switchTab('language'),
                      ),
                      _buildDivider(theme),
                      _buildSettingsListTile(
                        icon: Icons.public,
                        title: AppLocalizations.of(context)!.timezone,
                        onTap: () => controller.switchTab('timezone'),
                      ),
                      _buildDivider(theme),
                      _buildSettingsListTile(
                        icon: Icons.attach_money,
                        title: AppLocalizations.of(context)!.currency,
                        onTap: () => controller.switchTab('currency'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingL),
                _buildSectionHeader(AppLocalizations.of(context)!.wallet),
                const SizedBox(height: AppTheme.paddingS),
                GlassContainer(
                  child: _buildSettingsListTile(
                    icon: Icons.key,
                    title: AppLocalizations.of(context)!.viewRecoveryKey,
                    onTap: _showBackupWarningDialog,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingL),
                _buildSectionHeader(
                    AppLocalizations.of(context)!.serverConfiguration),
                const SizedBox(height: AppTheme.paddingS),
                GlassContainer(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingM,
                        vertical: AppTheme.paddingS * 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        side: BorderSide.none,
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        side: BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      title: Text(
                        'Advanced Server Settings',
                        style: TextStyle(
                          color: theme.primaryWhite,
                          fontSize: 14,
                        ),
                      ),
                      iconColor: theme.mutedText,
                      collapsedIconColor: theme.mutedText,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.network,
                                    style: TextStyle(color: theme.primaryWhite),
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedNetwork,
                                    dropdownColor: theme.tertiaryBlack,
                                    underline: const SizedBox(),
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: theme.mutedText),
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
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.paddingM),
                              Text(
                                AppLocalizations.of(context)!.esploraUrl,
                                style: TextStyle(
                                    color: theme.primaryWhite, fontSize: 14),
                              ),
                              const SizedBox(height: AppTheme.paddingS),
                              TextField(
                                controller: _esploraUrlController,
                                style: TextStyle(
                                    color: theme.primaryWhite, fontSize: 12),
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
                                      horizontal: 12, vertical: 10),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.save,
                                        color: Colors.amber, size: 20),
                                    onPressed: _saveEsploraUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.paddingM),
                              Text(
                                AppLocalizations.of(context)!.arkServer,
                                style: TextStyle(
                                    color: theme.primaryWhite, fontSize: 14),
                              ),
                              const SizedBox(height: AppTheme.paddingS),
                              TextField(
                                controller: _arkServerController,
                                style: TextStyle(
                                    color: theme.primaryWhite, fontSize: 12),
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
                                      horizontal: 12, vertical: 10),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.save,
                                        color: Colors.amber, size: 20),
                                    onPressed: _saveArkServerUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.paddingM),
                              Text(
                                AppLocalizations.of(context)!.boltzUrl,
                                style: TextStyle(
                                    color: theme.primaryWhite, fontSize: 14),
                              ),
                              const SizedBox(height: AppTheme.paddingS),
                              TextField(
                                controller: _boltzUrlController,
                                style: TextStyle(
                                    color: theme.primaryWhite, fontSize: 12),
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
                                      horizontal: 12, vertical: 10),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.save,
                                        color: Colors.amber, size: 20),
                                    onPressed: _saveBoltzUrl,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingL),
                _buildSectionHeader(AppLocalizations.of(context)!.about),
                const SizedBox(height: AppTheme.paddingS),
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.network,
                          style: TextStyle(color: theme.primaryWhite),
                        ),
                        Text(
                          _info?.network ??
                              AppLocalizations.of(context)!.loading,
                          style: TextStyle(color: theme.mutedText),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingL * 1.5),
                _buildSectionHeader(AppLocalizations.of(context)!.dangerZone,
                    color: Colors.red),
                const SizedBox(height: AppTheme.paddingS),
                GlassContainer(
                  child: _buildSettingsListTile(
                    icon: Icons.warning_amber_rounded,
                    title: AppLocalizations.of(context)!.resetWallet,
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _showResetWalletDialog,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingL * 2),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.paddingS),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? AppTheme.of(context).mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final theme = AppTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingS * 0.75),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.amber)
                      .withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? theme.primaryWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(theme) {
    return Divider(
      color: theme.borderColor.withAlpha((0.5 * 255).round()),
      height: 1,
      indent: AppTheme.paddingM,
      endIndent: AppTheme.paddingM,
    );
  }
}
