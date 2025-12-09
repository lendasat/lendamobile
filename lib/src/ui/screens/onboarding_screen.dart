import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/screens/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedOption;
  final TextEditingController _secretKeyController = TextEditingController();
  bool _isLoading = false;
  final SettingsService _settingsService = SettingsService();
  String? _esploraUrl;
  String? _arkServerUrl;
  String? _network;
  String? _boltzUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final esploraUrl = await _settingsService.getEsploraUrl();
      final arkServerUrl = await _settingsService.getArkServerUrl();
      final network = await _settingsService.getNetwork();
      final boltzUrl = await _settingsService.getBoltzUrl();

      setState(() {
        _esploraUrl = esploraUrl;
        _arkServerUrl = arkServerUrl;
        _network = network;
        _boltzUrl = boltzUrl;
        _isLoading = false;
      });
    } catch (err) {
      logger.e("Error loading settings: $err");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  void _handleOptionSelect(String option) {
    setState(() {
      _selectedOption = option;

      if (option == 'new') {
        _secretKeyController.clear();
      }
    });
  }

  void _handleContinue() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    final dataDir = await getApplicationSupportDirectory();

    try {
      // Debug mode - skip backend entirely
      if (_selectedOption == 'debug') {
        logger.i('Entering debug mode - skipping wallet setup');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const BottomNav(aspId: 'debug-mode')),
          );
        }
        return;
      }

      if (_selectedOption == 'new') {
        logger.i('Creating new wallet');

        try {
          var aspId = await setupNewWallet(
              dataDir: dataDir.path,
              network: _network!,
              esplora: _esploraUrl!,
              server: _arkServerUrl!,
              boltzUrl: _boltzUrl!);
          logger.i("Received id $aspId");

          // Navigate to dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => BottomNav(aspId: aspId)),
            );
          }
        } catch (e) {
          logger.e("Failed to create new wallet: $e");
          if (mounted) {
            _showErrorDialog(
                AppLocalizations.of(context)!.failedToCreateWallet,
                AppLocalizations.of(context)!
                    .errorCreatingWallet(e.toString()));
          }
        }
      } else if (_selectedOption == 'existing' &&
          _secretKeyController.text.isNotEmpty) {
        logger.i('Restoring wallet with key');

        try {
          var aspId = await restoreWallet(
              nsec: _secretKeyController.text,
              dataDir: dataDir.path,
              network: _network!,
              esplora: _esploraUrl!,
              server: _arkServerUrl!,
              boltzUrl: _boltzUrl!);
          logger.i("Received id $aspId");

          // Navigate to dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => BottomNav(aspId: aspId)),
            );
          }
        } catch (e) {
          logger.e("Failed to restore wallet: $e");
          if (mounted) {
            _showErrorDialog(
                AppLocalizations.of(context)!.failedToRestoreWallet,
                AppLocalizations.of(context)!
                    .errorRestoringWallet(e.toString()));
          }
        }
      }
    } finally {
      // Hide loading indicator if we're still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to build styled tagline
  TextSpan _buildStyledTagline(BuildContext context) {
    final text = AppLocalizations.of(context)!.appTagline;

    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 18,
        color: Theme.of(context).hintColor,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Header
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lendasat',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: _buildStyledTagline(context),
                    ),
                  ],
                ),
              ),

              // Option Selection
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.chooseAnOption,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New Wallet Option
                    _buildOptionCard(
                      title: AppLocalizations.of(context)!.createNewWallet,
                      subtitle: AppLocalizations.of(context)!
                          .generateANewSecureWallet,
                      option: 'new',
                    ),
                    const SizedBox(height: 16),

                    // Existing Wallet Option
                    _buildOptionCard(
                      title:
                          AppLocalizations.of(context)!.restoreExistingWallet,
                      subtitle: AppLocalizations.of(context)!
                          .useYourSecretKeyToAccessYourWallet,
                      option: 'existing',
                    ),
                    const SizedBox(height: 16),

                    // Debug Mode Option (only in debug builds)
                    _buildOptionCard(
                      title: 'Debug Mode',
                      subtitle: 'Skip wallet setup and enter app directly',
                      option: 'debug',
                    ),
                    const SizedBox(height: 24),

                    // Secret Key Input (shown only when "Existing Wallet" is selected)
                    if (_selectedOption == 'existing') ...[
                      Text(
                        AppLocalizations.of(context)!.enterYourNsec,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _secretKeyController,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!
                                .pasteYourRecoveryNsec,
                            hintStyle: TextStyle(color: Theme.of(context).hintColor),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_selectedOption == 'new' ||
                              _selectedOption == 'existing' ||
                              _selectedOption == 'debug'
                          ? _handleContinue
                          : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onSurface),
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.contin,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String option,
  }) {
    final bool isSelected = _selectedOption == option;
    

    return InkWell(
      onTap: () => _handleOptionSelect(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
