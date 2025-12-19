import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/bottom_nav.dart';
import 'package:ark_flutter/src/ui/screens/email_signup_screen.dart';
import 'package:ark_flutter/src/ui/screens/mnemonic_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedOption;

  void _handleOptionSelect(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _handleContinue() {
    // Debug mode - skip backend entirely
    if (_selectedOption == 'debug') {
      logger.i('Entering debug mode - skipping wallet setup');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => const BottomNav(aspId: 'debug-mode')),
      );
      return;
    }

    if (_selectedOption == 'new') {
      logger.i('Navigating to email signup screen for new wallet');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const EmailSignupScreen(isRestore: false),
        ),
      );
    } else if (_selectedOption == 'existing') {
      logger.i('Navigating to mnemonic input screen');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MnemonicInputScreen(),
        ),
      );
    }
    // Note: email_recovery option is disabled (Coming Soon)
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Header
                      const SizedBox(height: 32),
                      Column(
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
                      const SizedBox(height: 48),

                      // Option Selection
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

                      // Email Recovery Option (Coming Soon - disabled)
                      _buildOptionCard(
                        title: AppLocalizations.of(context)!.recoverWithEmail,
                        subtitle: AppLocalizations.of(context)!.comingSoon,
                        option: 'email_recovery',
                        isDisabled: true,
                      ),
                      const SizedBox(height: 16),

                      // Debug Mode Option (only in debug builds)
                      _buildOptionCard(
                        title: 'Debug Mode',
                        subtitle: 'Skip wallet setup and enter app directly',
                        option: 'debug',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedOption == 'new' ||
                          _selectedOption == 'existing' ||
                          _selectedOption == 'debug'
                      ? _handleContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
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
    bool isDisabled = false,
  }) {
    final bool isSelected = _selectedOption == option && !isDisabled;

    return InkWell(
      onTap: isDisabled ? null : () => _handleOptionSelect(option),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
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
      ),
    );
  }
}
