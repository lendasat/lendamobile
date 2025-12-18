import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/screens/bottom_nav.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Screen for collecting email during wallet signup.
/// After email is entered, creates wallet and registers with Lendasat.
class EmailSignupScreen extends StatefulWidget {
  /// If true, this is for restoring an existing wallet (mnemonic already entered)
  final bool isRestore;

  /// The mnemonic words (only used when isRestore is true)
  final String? mnemonicWords;

  const EmailSignupScreen({
    super.key,
    this.isRestore = false,
    this.mnemonicWords,
  });

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final SettingsService _settingsService = SettingsService();
  final LendasatService _lendasatService = LendasatService();
  bool _isLoading = false;
  String? _errorMessage;

  String? _esploraUrl;
  String? _arkServerUrl;
  String? _network;
  String? _boltzUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
      });
    } catch (err) {
      logger.e("Error loading settings: $err");
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim().toLowerCase();

    // Validate email
    if (email.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseEnterEmail;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.invalidEmail;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataDir = await getApplicationSupportDirectory();

      // Clear any previous recovery status flags
      await _settingsService.clearWordRecoveryStatus();

      String aspId;

      if (widget.isRestore && widget.mnemonicWords != null) {
        // Restore existing wallet from mnemonic
        logger.i('Restoring wallet from mnemonic');
        aspId = await restoreWallet(
          mnemonicWords: widget.mnemonicWords!,
          dataDir: dataDir.path,
          network: _network!,
          esplora: _esploraUrl!,
          server: _arkServerUrl!,
          boltzUrl: _boltzUrl!,
        );
      } else {
        // Create new wallet
        logger.i('Creating new wallet');
        aspId = await setupNewWallet(
          dataDir: dataDir.path,
          network: _network!,
          esplora: _esploraUrl!,
          server: _arkServerUrl!,
          boltzUrl: _boltzUrl!,
        );
      }

      logger.i("Wallet setup complete, aspId: $aspId");

      // Initialize Lendasat using the service
      // The service handles network mapping and API URL selection internally,
      // ensuring consistent key derivation between registration and authentication
      logger.i('Initializing Lendasat for registration');
      await _lendasatService.initialize();

      // Register with Lendasat using the email
      // Log the pubkey being registered for debugging
      try {
        final registrationPubkey = await _lendasatService.getPublicKey();
        logger.i('Registering with Lendasat, email: $email, pubkey: $registrationPubkey');
      } catch (e) {
        logger.w('Could not get pubkey for logging: $e');
      }

      try {
        final userId = await _lendasatService.register(
          email: email,
          name: 'Lendasat User',
          inviteCode: 'LAS-651K4',
        );
        logger.i('Lendasat registration successful, userId: $userId');

        // Save email for future reference
        await _settingsService.setUserEmail(email);
      } catch (e) {
        // Log but don't fail - user can still use the wallet
        // They might already be registered or registration might fail
        logger.w('Lendasat registration failed (non-fatal): $e');

        // Check if it's "already registered" error - that's fine
        if (!e.toString().toLowerCase().contains('already') &&
            !e.toString().toLowerCase().contains('exists')) {
          // Show warning but continue
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.registrationWarning,
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => BottomNav(aspId: aspId)),
          (route) => false,
        );
      }
    } catch (e) {
      logger.e("Failed to setup wallet: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                AppLocalizations.of(context)!.enterYourEmail,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.emailSignupDescription,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
              ),
              const SizedBox(height: 32),

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_isLoading,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  hintText: 'you@example.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  errorText: _errorMessage,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
                onSubmitted: (_) => _handleContinue(),
              ),
              const SizedBox(height: 16),

              // Info text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.emailUsageInfo,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          widget.isRestore
                              ? AppLocalizations.of(context)!.restoreWallet
                              : AppLocalizations.of(context)!.createWallet,
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
}
