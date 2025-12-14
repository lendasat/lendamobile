import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class RecoveryKeyView extends StatefulWidget {
  const RecoveryKeyView({super.key});

  @override
  State<RecoveryKeyView> createState() => _RecoveryKeyViewState();
}

class _RecoveryKeyViewState extends State<RecoveryKeyView> {
  String? _mnemonic;
  String? _nsec;
  bool _isHdWallet = false;
  bool _isLoading = true;
  bool _hasAcceptedWarning = false;

  @override
  void initState() {
    super.initState();
    _fetchRecoveryData();
  }

  Future<void> _fetchRecoveryData() async {
    try {
      var dataDir = await getApplicationSupportDirectory();

      final hdWallet = await isHdWallet(dataDir: dataDir.path);

      if (hdWallet) {
        final mnemonic = await getMnemonic(dataDir: dataDir.path);
        setState(() {
          _isHdWallet = true;
          _mnemonic = mnemonic;
          _isLoading = false;
        });
      } else {
        final key = await nsec(dataDir: dataDir.path);
        setState(() {
          _isHdWallet = false;
          _nsec = key;
          _isLoading = false;
        });
      }
    } catch (err) {
      logger.e("Error getting recovery data: $err");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    final recoveryData = _isHdWallet ? _mnemonic : _nsec;
    if (recoveryData != null) {
      Clipboard.setData(ClipboardData(text: recoveryData));
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

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: AppLocalizations.of(context)!.viewRecoveryKey,
        context: context,
        hasBackButton: true,
        onTap: () => controller.resetToMain(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
              ),
            )
          : !_hasAcceptedWarning
              ? _buildWarningView(isDark, controller)
              : _buildRecoveryKeyView(isDark),
    );
  }

  Widget _buildWarningView(bool isDark, SettingsController controller) {
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
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
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
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
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
            _buildWarningPoint(
              context,
              Icons.person_off,
              'Never share with anyone',
            ),
            _buildWarningPoint(
              context,
              Icons.screenshot_monitor,
              'Never take screenshots',
            ),
            _buildWarningPoint(
              context,
              Icons.cloud_off,
              'Never store digitally or online',
            ),
            _buildWarningPoint(
              context,
              Icons.edit_note,
              'Write it down on paper and store safely',
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),

            // Continue button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasAcceptedWarning = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorBitcoin,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.iUnderstand,
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

  Widget _buildRecoveryKeyView(bool isDark) {
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
                color: AppTheme.colorBitcoin.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    decoration: BoxDecoration(
                      color: AppTheme.colorBitcoin.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Icon(
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
                          'Save your recovery phrase securely',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your recovery phrase is the key to your wallet',
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

            // Warning reminder
            Container(
              padding: const EdgeInsets.all(AppTheme.elementSpacing),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.errorColor,
                    size: AppTheme.iconSize,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: Text(
                      'Never share your recovery phrase with anyone. Anyone with this phrase can access your funds.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding * 1.5),

            // Recovery phrase section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Recovery Phrase',
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
                      _isHdWallet ? '12 Words' : 'Legacy Key',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing),

            // Recovery phrase display
            Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  if (_isHdWallet && _mnemonic != null)
                    _buildMnemonicGrid(_mnemonic!)
                  else if (!_isHdWallet && _nsec != null)
                    _buildLegacyKey(_nsec!),

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
                        side: BorderSide(color: AppTheme.colorBitcoin),
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
            const SizedBox(height: AppTheme.cardPadding),

            // Instructions
            Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  _buildInstruction(context, '1', 'Write down these words in the exact order'),
                  _buildInstruction(context, '2', 'Store them in a safe place'),
                  _buildInstruction(context, '3', 'Never share them with anyone'),
                  _buildInstruction(context, '4', 'Never store them digitally or take screenshots'),
                ],
              ),
            ),

            if (!_isHdWallet) ...[
              const SizedBox(height: AppTheme.cardPadding),
              Container(
                padding: const EdgeInsets.all(AppTheme.elementSpacing),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: AppTheme.elementSpacing),
                    Expanded(
                      child: Text(
                        'This is a legacy wallet. Consider creating a new wallet with mnemonic backup for better security.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.cardPadding * 2),
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
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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

  Widget _buildLegacyKey(String nsec) {
    return SelectableText(
      nsec,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildInstruction(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.elementSpacing * 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.elementSpacing * 0.5),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
