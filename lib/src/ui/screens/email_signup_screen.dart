import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/screens/bottom_nav.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
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
    logger.i('[SIGNUP] Starting signup flow with email: $email');

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
      logger.i('[SIGNUP] Step 1: Getting application support directory...');
      final dataDir = await getApplicationSupportDirectory();
      logger.i('[SIGNUP] Step 1 DONE: dataDir = ${dataDir.path}');

      logger.i('[SIGNUP] Step 2: Clearing previous recovery status...');
      await _settingsService.clearWordRecoveryStatus();
      logger.i('[SIGNUP] Step 2 DONE');

      logger.i('[SIGNUP] Step 3: Checking settings - network: $_network, esplora: $_esploraUrl, arkServer: $_arkServerUrl, boltz: $_boltzUrl');

      String aspId;

      if (widget.isRestore && widget.mnemonicWords != null) {
        logger.i('[SIGNUP] Step 4: Restoring wallet from mnemonic...');
        aspId = await restoreWallet(
          mnemonicWords: widget.mnemonicWords!,
          dataDir: dataDir.path,
          network: _network!,
          esplora: _esploraUrl!,
          server: _arkServerUrl!,
          boltzUrl: _boltzUrl!,
        );
        logger.i('[SIGNUP] Step 4 DONE: Wallet restored, aspId: $aspId');
      } else {
        logger.i('[SIGNUP] Step 4: Creating new wallet...');
        aspId = await setupNewWallet(
          dataDir: dataDir.path,
          network: _network!,
          esplora: _esploraUrl!,
          server: _arkServerUrl!,
          boltzUrl: _boltzUrl!,
        );
        logger.i('[SIGNUP] Step 4 DONE: Wallet created, aspId: $aspId');
      }

      // Track wallet creation and identify user
      logger.i('[SIGNUP] Step 4.5: Identifying user for analytics...');
      await AnalyticsService().identifyUser();
      await AnalyticsService().trackWalletCreated(isRestore: widget.isRestore);
      logger.i('[SIGNUP] Step 4.5 DONE: User identified');

      logger.i('[SIGNUP] Step 5: Initializing Lendasat service...');
      await _lendasatService.initialize();
      logger.i('[SIGNUP] Step 5 DONE: Lendasat initialized');

      // Register with Lendasat using the email
      logger.i('[SIGNUP] Step 6: Getting public key for registration...');
      try {
        final registrationPubkey = await _lendasatService.getPublicKey();
        logger.i('[SIGNUP] Step 6 DONE: pubkey: $registrationPubkey');
      } catch (e) {
        logger.w('[SIGNUP] Step 6 WARNING: Could not get pubkey: $e');
      }

      logger.i('[SIGNUP] Step 7: Registering with Lendasat...');
      try {
        final userId = await _lendasatService.register(
          email: email,
          name: 'Lendasat User',
          inviteCode: 'LAS-651K4',
        );
        logger.i('[SIGNUP] Step 7 DONE: Registration successful, userId: $userId');

        logger.i('[SIGNUP] Step 8: Saving user email...');
        await _settingsService.setUserEmail(email);
        logger.i('[SIGNUP] Step 8 DONE');
      } catch (e) {
        logger.w('[SIGNUP] Step 7 WARNING: Lendasat registration failed (non-fatal): $e');

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

      logger.i('[SIGNUP] Step 9: Navigating to dashboard...');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => BottomNav(aspId: aspId)),
          (route) => false,
        );
      }
      logger.i('[SIGNUP] COMPLETE!');
    } catch (e, stackTrace) {
      logger.e('[SIGNUP] FAILED with error: $e');
      logger.e('[SIGNUP] Stack trace: $stackTrace');
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
              Expanded(
                child: SingleChildScrollView(
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
                          fillColor: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Continue button
              LongButtonWidget(
                title: widget.isRestore
                    ? AppLocalizations.of(context)!.restoreWallet
                    : AppLocalizations.of(context)!.createWallet,
                customWidth: double.infinity,
                customHeight: 56,
                isLoading: _isLoading,
                onTap: _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
