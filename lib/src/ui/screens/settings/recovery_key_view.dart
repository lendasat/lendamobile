import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
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
  final List<TextEditingController> _wordControllers =
      List.generate(12, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(12, (_) => FocusNode());
  final PageController _confirmPageController = PageController();
  bool _onLastPage = false;
  bool _isVerifying = false;
  String? _verificationError;
  List<String> _bipWords = [];

  @override
  void initState() {
    super.initState();
    _fetchRecoveryData();
    _loadBipWords();

    // Add focus listeners for auto-navigation
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => _onFocusChange(i));
    }

    // Add text change listeners for paste detection
    for (int i = 0; i < _wordControllers.length; i++) {
      _wordControllers[i].addListener(() => _onTextChanged(i));
    }
  }

  Future<void> _loadBipWords() async {
    try {
      final String bipWordsText =
          await rootBundle.loadString('assets/textfiles/bip_words.txt');
      setState(() {
        _bipWords = bipWordsText.split(' ');
      });
    } catch (e) {
      logger.e("Error loading BIP words: $e");
    }
  }

  void _onFocusChange(int index) {
    if (_focusNodes[index].hasFocus && _confirmPageController.hasClients) {
      int pageIndex = index ~/ 4;
      if (_confirmPageController.page?.round() != pageIndex) {
        _confirmPageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onTextChanged(int index) {
    String text = _wordControllers[index].text.trim();

    // Check for pasted mnemonic (multiple words)
    List<String> words = text
        .split(RegExp(r'[,\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.trim().toLowerCase())
        .toList();

    if (words.length >= 12) {
      _autoFillMnemonic(words);
    }
  }

  void _autoFillMnemonic(List<String> words) async {
    int wordCount = words.length > 12 ? 12 : words.length;

    for (int i = 0; i < wordCount && i < _wordControllers.length; i++) {
      if (_wordControllers[i].text != words[i]) {
        _wordControllers[i].text = words[i];
      }
    }

    setState(() {});

    await Future.delayed(const Duration(milliseconds: 100));

    if (wordCount == 12 && _confirmPageController.hasClients) {
      _confirmPageController.animateToPage(
        2, // Last page
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _onLastPage = true;
      });
    }

    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _moveToNextField() {
    int currentFocusIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (currentFocusIndex == -1 ||
        currentFocusIndex == _focusNodes.length - 1) {
      return;
    }

    if ((currentFocusIndex + 1) % 4 == 0) {
      _nextConfirmPage();
    }

    _focusNodes[currentFocusIndex].unfocus();
    FocusScope.of(context).requestFocus(_focusNodes[currentFocusIndex + 1]);
    setState(() {});
  }

  void _nextConfirmPage() async {
    if (_confirmPageController.hasClients) {
      await _confirmPageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    }
  }

  bool _isValidWord(String word) {
    return _bipWords.contains(word.toLowerCase());
  }

  @override
  void dispose() {
    for (var controller in _wordControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _confirmPageController.dispose();
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
    } catch (err) {
      logger.e("Error getting recovery data: $err");
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Wallet mnemonic doesn't exist. Please contact support.";
      });
    }
  }

  void _clearWordControllers() {
    for (var controller in _wordControllers) {
      controller.clear();
    }
    _onLastPage = false;
    if (_confirmPageController.hasClients) {
      _confirmPageController.jumpToPage(0);
    }
  }

  void _proceedToShowMnemonic() {
    logger.i(
        "_proceedToShowMnemonic called, changing step from $_currentStep to 1");
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

    // Check all 12 words
    final enteredMnemonic = _wordControllers
        .map((controller) => controller.text.trim().toLowerCase())
        .join(' ');
    final expectedMnemonic = words.map((w) => w.toLowerCase()).join(' ');

    if (enteredMnemonic == expectedMnemonic) {
      _completeRecoverySetup();
    } else {
      setState(() {
        _isVerifying = false;
        _verificationError =
            AppLocalizations.of(context)!.incorrectWordsPleaseTryAgain;
      });
      // Reset to first page on error
      _clearWordControllers();
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
    // Show confirmation bottomsheet
    final confirmed = await arkBottomSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              AppLocalizations.of(context)!.skipVerification,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              AppLocalizations.of(context)!.skipVerificationWarning,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              buttonType: ButtonType.transparent,
              title: AppLocalizations.of(context)!.cancel,
              onTap: () => Navigator.pop(context, false),
              customWidth: double.infinity,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            LongButtonWidget(
              buttonType: ButtonType.solid,
              title: AppLocalizations.of(context)!.skipAtOwnRisk,
              onTap: () => Navigator.pop(context, true),
              customWidth: double.infinity,
              backgroundColor: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _completeRecoverySetup();
    }
  }

  void _copyToClipboard() {
    if (_mnemonic != null) {
      Clipboard.setData(ClipboardData(text: _mnemonic!));
      OverlayService().showSuccess(
        AppLocalizations.of(context)!.recoveryPhraseCopiedToClipboard,
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
      appBar: BitNetAppBar(
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
              ),
            )
          : _errorMessage != null
              ? _buildErrorView(isDark)
              : _buildCurrentStep(isDark),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    logger.i(
        "_buildCurrentStep called with _currentStep: $_currentStep, _isLoading: $_isLoading");
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
                    AppLocalizations.of(context)!
                        .neverShareYourRecoveryKeyWithAnyone,
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
            _buildWarningPoint(
                context, Icons.person_off, 'Never share with anyone'),
            _buildWarningPoint(
                context, Icons.screenshot_monitor, 'Never take screenshots'),
            _buildWarningPoint(
                context, Icons.cloud_off, 'Never store digitally or online'),
            _buildWarningPoint(context, Icons.edit_note,
                'Write it down on paper and store safely'),

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
      padding:
          const EdgeInsets.symmetric(vertical: AppTheme.elementSpacing * 0.5),
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
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
                          AppLocalizations.of(context)!
                              .writeDownYourRecoveryPhrase,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.youWillNeedToConfirmIt,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.white60
                                        : AppTheme.black60,
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
                        label:
                            Text(AppLocalizations.of(context)!.copyToClipboard),
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
                _clearWordControllers();
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
    if (_mnemonic == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
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
                          AppLocalizations.of(context)!
                              .verifyYourRecoveryPhrase,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.enterTheFollowingWords,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),

            // PageView for mnemonic input - masked for PostHog session replay
            PostHogMaskWidget(
              child: SizedBox(
                height: 320,
                child: PageView(
                  controller: _confirmPageController,
                  onPageChanged: (val) {
                    setState(() {
                      _onLastPage = (val == 2);
                    });
                  },
                  children: [
                    _buildConfirmInputPage(0), // Words 1-4
                    _buildConfirmInputPage(1), // Words 5-8
                    _buildConfirmInputPage(2), // Words 9-12
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.elementSpacing),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _confirmPageController.hasClients &&
                          (_confirmPageController.page?.round() ?? 0) == index
                      ? 24
                      : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _confirmPageController.hasClients &&
                            (_confirmPageController.page?.round() ?? 0) == index
                        ? AppTheme.colorBitcoin
                        : Theme.of(context).hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppTheme.cardPadding),

            // Error message
            if (_verificationError != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.elementSpacing),
                margin: const EdgeInsets.only(bottom: AppTheme.cardPadding),
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

            // Action button
            LongButtonWidget(
              title:
                  _onLastPage ? AppLocalizations.of(context)!.verify : 'Next',
              customWidth: double.infinity,
              customHeight: 56,
              isLoading: _isVerifying,
              onTap: _onLastPage ? _verifyWords : _nextConfirmPage,
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

  Widget _buildConfirmInputPage(int pageIndex) {
    int startIndex = pageIndex * 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          int wordIndex = startIndex + i;
          return _buildConfirmWordField(wordIndex);
        }),
      ),
    );
  }

  Widget _buildConfirmWordField(int index) {
    final controller = _wordControllers[index];
    final focusNode = _focusNodes[index];
    final bool isValid =
        controller.text.isNotEmpty && _isValidWord(controller.text);
    final bool isInvalid =
        controller.text.isNotEmpty && !_isValidWord(controller.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          color: isValid
              ? AppTheme.successColor
              : (isInvalid
                  ? AppTheme.errorColor
                  : Theme.of(context).colorScheme.onSurface),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: '${index + 1}.',
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
          prefixIcon: Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              '${index + 1}.',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid
                  ? AppTheme.successColor.withValues(alpha: 0.5)
                  : (isInvalid
                      ? AppTheme.errorColor.withValues(alpha: 0.5)
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2)),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid
                  ? AppTheme.successColor
                  : (isInvalid ? AppTheme.errorColor : AppTheme.colorBitcoin),
              width: 2,
            ),
          ),
        ),
        textInputAction:
            index < 11 ? TextInputAction.next : TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (value) {
          setState(() {});
          // Auto-advance if valid word is complete
          if (_isValidWord(value.trim().toLowerCase())) {
            final matches = _bipWords
                .where((w) => w.startsWith(value.toLowerCase()))
                .toList();
            final longestMatch = matches.isEmpty
                ? 0
                : matches.map((w) => w.length).reduce((a, b) => a > b ? a : b);
            if (value.length == longestMatch) {
              _moveToNextField();
            }
          }
        },
        onFieldSubmitted: (_) {
          if (index < 11) {
            _moveToNextField();
          } else {
            FocusScope.of(context).unfocus();
          }
        },
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
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
