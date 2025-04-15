import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/ui/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:restart_app/restart_app.dart';

class SettingsScreen extends StatefulWidget {
  final String aspId;

  const SettingsScreen({
    Key? key,
    required this.aspId,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _nsec = 'Unknown';
  Info? _info;
  String _selectedNetwork = 'Regtest';

  // Create an instance of SettingsService
  final SettingsService _settingsService = SettingsService();

  // Text editing controllers for URL inputs
  final TextEditingController _esploraUrlController = TextEditingController();
  final TextEditingController _arkServerController = TextEditingController();

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

      setState(() {
        _esploraUrlController.text = esploraUrl;
        _arkServerController.text = arkServerUrl;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Esplora URL saved  - will only take effect after a restart')),
      );
      logger.i("Esplora URL saved: ${_esploraUrlController.text}");
    } catch (err) {
      logger.e("Error saving Esplora URL: $err");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save Esplora URL')),
      );
    }
  }

  // Save Network URL
  Future<void> _saveNetwork(String network) async {
    try {
      await _settingsService.saveNetwork(network);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Network saved - will only take effect after a restart')),
      );
      logger.i("Esplora URL saved: ${_esploraUrlController.text}");
    } catch (err) {
      logger.e("Error saving Esplora URL: $err");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save Esplora URL')),
      );
    }
  }

  // Save Ark Server URL
  Future<void> _saveArkServerUrl() async {
    try {
      await _settingsService.saveArkServerUrl(_arkServerController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Ark Server URL saved - will only take effect after a restart')),
      );
      logger.i("Ark Server URL saved: ${_arkServerController.text}");
    } catch (err) {
      logger.e("Error saving Ark Server URL: $err");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save Ark Server URL')),
      );
    }
  }

  @override
  void dispose() {
    _esploraUrlController.dispose();
    _arkServerController.dispose();
    super.dispose();
  }

  void _showBackupWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Security Warning',
          style: TextStyle(color: Colors.amber),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Never share your recovery key with anyone!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Anyone with this key can access your wallet and steal your funds. Store it in a secure place.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRecoveryKeyDialog();
            },
            child: const Text('I UNDERSTAND',
                style: TextStyle(color: Colors.amber)),
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
        backgroundColor: Colors.grey[900],
        title: const Text('Your Recovery Phrase',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _nsec,
                        style: const TextStyle(
                          color: Colors.white,
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
                  const SnackBar(
                      content: Text('Recovery phrase copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.amber),
              label: const Text('COPY TO CLIPBOARD'),
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
            child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Reset Wallet', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This will delete all wallet data from this device. Make sure you have backed up your recovery phrase before proceeding. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
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

              Restart.restartApp(
                /// In Web Platform, Fill webOrigin only when your new origin is different than the app's origin
                // webOrigin: 'http://example.com',

                // Customizing the notification message only on iOS
                notificationTitle: 'Restarting App',
                notificationBody: 'Please tap here to open the app again.',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('RESET',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                _buildSectionHeader('Wallet'),
                _buildSettingsCard([
                  ListTile(
                    title: const Text('View Recovery Key',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Backup your wallet with these key',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showBackupWarningDialog,
                  ),
                ]),

                const SizedBox(height: 24),

                // Server Settings Section
                _buildSectionHeader('Server Configuration'),
                _buildSettingsCard([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      title: const Text('Network',
                          style: TextStyle(color: Colors.white)),
                      trailing: DropdownButton<String>(
                        value: _selectedNetwork,
                        dropdownColor: Colors.grey[850],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.grey),
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
                        const Text(
                          'Esplora URL',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _esploraUrlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: SettingsService.defaultEsploraUrl,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[800],
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
                        const Text(
                          'Ark Server',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _arkServerController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: SettingsService.defaultArkServerUrl,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[800],
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
                ]),

                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader('About'),
                _buildSettingsCard([
                  ListTile(
                    title: const Text('Network',
                        style: TextStyle(color: Colors.white)),
                    subtitle: _info != null
                        ? Text(
                            _info!.network,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          )
                        : Text("loading",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                  ),
                ]),

                const SizedBox(height: 32),

                // Danger Zone
                _buildSectionHeader('Danger Zone', color: Colors.red),
                _buildSettingsCard([
                  ListTile(
                    title: const Text('Reset Wallet',
                        style: TextStyle(color: Colors.red)),
                    subtitle: Text(
                      'Delete all wallet data from this device',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: const Icon(Icons.warning_amber_rounded,
                        color: Colors.red),
                    onTap: _showResetWalletDialog,
                  ),
                ], borderColor: Colors.red.withOpacity(0.3)),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = Colors.amber}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children,
      {Color borderColor = Colors.transparent}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
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
                    color: Colors.grey[800],
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],
              );
            } else {
              return child;
            }
          }).toList(),
        ],
      ),
    );
  }
}
