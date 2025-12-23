import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/bottom_nav.dart';
import 'package:ark_flutter/src/ui/screens/email_signup_screen.dart';
import 'package:ark_flutter/src/ui/screens/mnemonic_input_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  String _version = '';
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _version = 'v1.0.0';
      });
    }
  }

  void _handleVersionTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      _tapCount++;
      if (_tapCount >= 3) {
        _openDebugMode();
        _tapCount = 0;
      }
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;
  }

  void _openDebugMode() {
    logger.i("Opening Debug Mode via triple tap");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const BottomNav(aspId: 'debug-mode'),
      ),
    );
  }

  void _handleCreateWallet() {
    logger.i('Navigating to email signup screen for new wallet');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailSignupScreen(isRestore: false),
      ),
    );
  }

  void _handleRestoreWallet() {
    logger.i('Navigating to mnemonic input screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MnemonicInputScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: false,
      ),
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding * 1.5,
            vertical: AppTheme.cardPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppTheme.cardPadding * 2),
              // Spacer to push content down
              const Spacer(flex: 2),
              // Bani mascot image
              Flexible(
                flex: 3,
                child: Builder(
                  builder: (context) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    final baniSize = screenHeight * 0.25;
                    return Container(
                      constraints: BoxConstraints(
                        maxHeight: baniSize,
                        maxWidth: baniSize,
                      ),
                      child: Image.asset(
                        'assets/images/bani/bani_register.png',
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              // Spacer between image and buttons
              const Spacer(flex: 2),
              const SizedBox(height: AppTheme.cardPadding * 4),
              // Buttons section
              LongButtonWidget(
                buttonType: ButtonType.transparent,
                title: AppLocalizations.of(context)!.restoreExistingWallet,
                customWidth: double.infinity,
                onTap: _handleRestoreWallet,
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              LongButtonWidget(
                buttonType: ButtonType.solid,
                title: AppLocalizations.of(context)!.createNewWallet,
                customWidth: double.infinity,
                onTap: _handleCreateWallet,
              ),
              // Spacer to push footer down
              const SizedBox(height: AppTheme.cardPadding * 1.5),
              // Footer with AGBS and version
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to AGBS/Terms page when available
                      logger.i('AGBS tapped');
                    },
                    child: Text(
                      "Terms & Privacy",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  GestureDetector(
                    onTap: _handleVersionTap,
                    child: Text(
                      _version,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.5),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
