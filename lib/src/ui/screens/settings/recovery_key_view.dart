import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

/// Recovery key view with multi-step flow:
/// 0: Warning view
/// 1: Show mnemonic
/// 2: Confirm mnemonic (type back random words)
/// 3: Success
class RecoveryKeyView extends StatefulWidget {
  const RecoveryKeyView({super.key});

  @override
  State<RecoveryKeyView> createState() => _RecoveryKeyViewState();
}

class _RecoveryKeyViewState extends State<RecoveryKeyView> {
  String? _mnemonic;
  bool _isLoading = true;
  String? _errorMessage;

  // Multi-step flow state
  int _currentStep = 0; // 0: warning, 1: show mnemonic, 2: confirm, 3: success

  // For confirmation step
  final List<TextEditingController> _wordControllers = [];
  final List<int> _verifyWordIndices = []; // Random word indices to verify
  bool _isVerifying = false;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _fetchRecoveryData();
  }

  @override
  void dispose() {
    for (var controller in _wordControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchRecoveryData() async {
    try {
      var dataDir = await getApplicationSupportDirectory();

      final mnemonic = await getMnemonic(dataDir: dataDir.path);
      setState(() {
        _mnemonic = mnemonic;
        _isLoading = false;
      });
      _setupVerificationWords();
    } catch (err) {
      logger.e("Error getting recovery data: $err");
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Wallet mnemonic doesn't exist. Please contact support.";
      });
    }
  }

  void _setupVerificationWords() {
    if (_mnemonic == null) return;

    final words = _mnemonic!.split(' ');

    // Select 4 random word indices for verification
    final indices = List<int>.generate(words.length, (i) => i);
    indices.shuffle();
    _verifyWordIndices.clear();
    _verifyWordIndices.addAll(indices.take(4).toList()..sort());

    // Create controllers for verification
    _wordControllers.clear();
    for (var i = 0; i < 4; i++) {
      _wordControllers.add(TextEditingController());
    }
  }

  void _proceedToShowMnemonic() {
    logger.i("_proceedToShowMnemonic called, changing step from $_currentStep to 1");
    setState(() {
      _currentStep = 1; // Show mnemonic
    });
    logger.i("_currentStep is now: $_currentStep");
  }

  void _verifyWords() {
    if (_mnemonic == null) return;

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    final words = _mnemonic!.split(' ');
    bool allCorrect = true;

    for (int i = 0; i < _verifyWordIndices.length; i++) {
      final expectedWord = words[_verifyWordIndices[i]].toLowerCase().trim();
      final enteredWord = _wordControllers[i].text.toLowerCase().trim();

      if (expectedWord != enteredWord) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      _completeRecoverySetup();
    } else {
      setState(() {
        _isVerifying = false;
        _verificationError = AppLocalizations.of(context)!.incorrectWordsPleaseTryAgain;
      });
    }
  }

  Future<void> _completeRecoverySetup() async {
    // Mark word recovery as complete
    await SettingsService().setWordRecoveryComplete();

    setState(() {
      _currentStep = 3; // Success
      _isVerifying = false;
    });
  }

  Future<void> _skipVerification() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.skipVerification),
        content: Text(AppLocalizations.of(context)!.skipVerificationWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text(AppLocalizations.of(context)!.skipAtOwnRisk),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _completeRecoverySetup();
    }
  }

  void _copyToClipboard() {
    if (_mnemonic != null) {
      Clipboard.setData(ClipboardData(text: _mnemonic!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.recoveryPhraseCopiedToClipboard,
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String appBarTitle;
    switch (_currentStep) {
      case 0:
        appBarTitle = AppLocalizations.of(context)!.securityWarning;
        break;
      case 1:
        appBarTitle = AppLocalizations.of(context)!.viewRecoveryKey;
        break;
      case 2:
        appBarTitle = AppLocalizations.of(context)!.confirmRecoveryPhrase;
        break;
      case 3:
        appBarTitle = AppLocalizations.of(context)!.recoveryComplete;
        break;
      default:
        appBarTitle = AppLocalizations.of(context)!.viewRecoveryKey;
    }

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: appBarTitle,
        context: context,
        hasBackButton: true,
        onTap: () {
          if (_currentStep > 0 && _currentStep < 3) {
            // Go back a step
            setState(() {
              _currentStep--;
            });
          } else {
            controller.resetToMain();
          }
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
              ),
            )
          : _errorMessage != null
              ? _buildErrorView(isDark)
              : _buildCurrentStep(isDark),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    logger.i("_buildCurrentStep called with _currentStep: $_currentStep, _isLoading: $_isLoading");
    switch (_currentStep) {
      case 0:
        return _buildWarningView(isDark);
      case 1:
        return _buildShowMnemonicView(isDark);
      case 2:
        return _buildConfirmMnemonicView(isDark);
      case 3:
        return _buildSuccessView(isDark);
      default:
        return _buildWarningView(isDark);
    }
  }

  Widget _buildErrorView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              _errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningView(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.cardPadding * 2),

            // Warning icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),

            // Title
            Text(
              AppLocalizations.of(context)!.securityWarning,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),

            // Warning content
            Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.neverShareYourRecoveryKeyWithAnyone,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  Text(
                    AppLocalizations.of(context)!.anyoneWithThisKeyCan,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.white70 : AppTheme.black70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),

            // Instructions
            _buildWarningPoint(context, Icons.person_off, 'Never share with anyone'),
            _buildWarningPoint(context, Icons.screenshot_monitor, 'Never take screenshots'),
            _buildWarningPoint(context, Icons.cloud_off, 'Never store digitally or online'),
            _buildWarningPoint(context, Icons.edit_note, 'Write it down on paper and store safely'),

            const SizedBox(height: AppTheme.cardPadding * 2),

            // Continue button
            LongButtonWidget(
              title: AppLocalizations.of(context)!.iUnderstand,
              customWidth: double.infinity,
              customHeight: 56,
              onTap: () {
                logger.i("Button pressed! Current step: $_currentStep");
                _proceedToShowMnemonic();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningPoint(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.elementSpacing * 0.5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: AppTheme.elementSpacing),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMnemonicView(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.cardPadding),

            // Header section
            Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    decoration: BoxDecoration(
                      color: AppTheme.colorBitcoin.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: AppTheme.iconSize * 1.5,
                      color: AppTheme.colorBitcoin,
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.writeDownYourRecoveryPhrase,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.youWillNeedToConfirmIt,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.white60 : AppTheme.black60,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),

            // Recovery phrase section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.yourRecoveryPhrase,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.key,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '12 Words',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing),

            // Recovery phrase display - masked for PostHog session replay
            PostHogMaskWidget(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    if (_mnemonic != null) _buildMnemonicGrid(_mnemonic!),

                    const SizedBox(height: AppTheme.cardPadding),

                    // Copy button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        label: Text(AppLocalizations.of(context)!.copyToClipboard),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.colorBitcoin,
                          side: const BorderSide(color: AppTheme.colorBitcoin),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding * 2),

            // Continue to verify button
            LongButtonWidget(
              title: AppLocalizations.of(context)!.continueToVerify,
              customWidth: double.infinity,
              customHeight: 56,
              onTap: () {
                _setupVerificationWords();
                setState(() {
                  _currentStep = 2;
                });
              },
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmMnemonicView(bool isDark) {
    if (_mnemonic == null || _verifyWordIndices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.cardPadding),

            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    decoration: BoxDecoration(
                      color: AppTheme.colorBitcoin.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: const Icon(
                      Icons.quiz_outlined,
                      size: AppTheme.iconSize * 1.5,
                      color: AppTheme.colorBitcoin,
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.verifyYourRecoveryPhrase,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.enterTheFollowingWords,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.white60 : AppTheme.black60,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding * 1.5),

            // Word input fields - masked for PostHog session replay
            PostHogMaskWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _verifyWordIndices.length; i++) ...[
                    Text(
                      'Word #${_verifyWordIndices[i] + 1}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _wordControllers[i],
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterWord,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.colorBitcoin, width: 2),
                        ),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: i < _verifyWordIndices.length - 1
                          ? TextInputAction.next
                          : TextInputAction.done,
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                  ],
                ],
              ),
            ),

            // Error message
            if (_verificationError != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.elementSpacing),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _verificationError!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppTheme.cardPadding),

            // Verify button
            LongButtonWidget(
              title: AppLocalizations.of(context)!.verify,
              customWidth: double.infinity,
              customHeight: 56,
              isLoading: _isVerifying,
              onTap: _verifyWords,
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Skip at own risk
            Center(
              child: TextButton(
                onPressed: _skipVerification,
                child: Text(
                  AppLocalizations.of(context)!.skipAtOwnRisk,
                  style: TextStyle(
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    final controller = context.read<SettingsController>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              AppLocalizations.of(context)!.recoveryPhraseConfirmed,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              AppLocalizations.of(context)!.yourRecoveryPhraseIsSecured,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding * 2),
            LongButtonWidget(
              title: AppLocalizations.of(context)!.done,
              customWidth: double.infinity,
              customHeight: 56,
              onTap: () => controller.resetToMain(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMnemonicGrid(String mnemonicText) {
    final words = mnemonicText.split(' ');
    return Column(
      children: [
        for (int i = 0; i < words.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
            child: Row(
              children: [
                Expanded(
                  child: _buildWordCard(i + 1, words[i]),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                if (i + 1 < words.length)
                  Expanded(
                    child: _buildWordCard(i + 2, words[i + 1]),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWordCard(int number, String word) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding * 0.75,
        vertical: AppTheme.elementSpacing,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.elementSpacing),
          Expanded(
            child: Text(
              word,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
